class ScenarioAnalysisBuilder

  def initialize(decision, show_published)
    @decision = decision
    @show_published = show_published

    coc_query = @decision.cached_option_categories
                  .includes(:default_low_option, :default_high_option, :primary_detail, cached_options: [:cached_option_detail_values])
    @option_categories = sorted_and_indexed_records(coc_query)

    co_query = @decision.cached_options.includes(:cached_option_detail_values, :cached_option_category)
    @options = sorted_and_indexed_records(co_query)
    @criteria = sorted_and_indexed_records(@decision.cached_criteria)
    @option_details = sorted_and_indexed_records(@decision.cached_option_details)
    @vote_captions = decision.voting_settings.base_voting_captions
  end

  def _solve_config
    @solve_config ||=
      begin
        solve_config = SolveConfig.create_for(@decision, nil, @showing_published)
        solve_config.schedule_solve
        solve_config
      end
  end

  def _scenario_config
    @scenario_config ||= @solve_config.scenario_config
  end

  def load_scenarios
    @loaded ||= _solve_config.load_scenarios(include_global: true)
  end

  def solved_at
    loaded = load_scenarios
    return nil unless loaded[:meta][:status] == 'success'
    loaded[:meta][:updated_at]
  end

  def scenario_list
    load_scenarios[:data] || []
  end

  def scenario_at(rank)
    scenario_list.find { |scenario| scenario.rank === rank }
  end

  def global_scenario
    @global_scenario ||= scenario_at(0)
  end

  def top_scenario
    return nil if _solve_config.scenario_config.skip_solver
    @top_scenario ||= scenario_at(1)
  end

  def self.data_sets
    [:scenario_results, :scenario_calculations]
  end

  def get_data(data)
    case data.to_sym
    when :scenario_results
      result_rows
    when :scenario_calculations
      if top_scenario.present?
        _calculation_stats(top_scenario)
      else
        nil
      end
    else
      nil
    end
  end

  def self.voting_captions(decision)
    @vote_captions ||=
      begin

        (1..9).inject({}) do |acc, i|
          acc["voting.bin#{i}_caption"] = decision.t("voting.bin#{i}_caption").to_s
          acc
        end
      end

  end

  def self.vote_values(decision, histogram, value_override = nil)
    captions = decision.voting_settings.base_voting_captions
    vote_values_from_captions(captions, histogram, value_override)
  end

  def self.vote_values_from_captions(captions, histogram, value_override = nil)

    bin_name_map = [
      [9],
      [1, 9],
      [1, 5, 9],
      [1, 4, 6, 9],
      [1, 4, 5, 6, 9],
      [1, 2, 4, 6, 8, 9],
      [1, 2, 3, 5, 7, 8, 9],
      [1, 2, 3, 4, 6, 7, 8, 9],
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
    ]

    values = {}
    histogram.each_with_index.map do |value, index|
      value = value_override.nil? ? value : value_override # when we just want the captions
      if histogram.length <= bin_name_map.length
        i = bin_name_map[(histogram.length - 1)][index]
        values[captions["voting.bin#{i}_caption"]] = value
      else
        values[index + 1] = value
      end
    end

    values
  end

  def rescale_approval(input)
    rescale(input, 0, 1, 0.001, 100)
  end

  def rescale_ethelo(input)
    rescale(input, -1, 1, 0.001, 100)
  end

  def rescale_dissonance(input)
    rescale(input, 0, 1, 0.001, 100)
  end

  def rescale_support(input)
    lowest_possible = _scenario_config.support_only ? 0 : -1
    rescale(input, lowest_possible, 1, 0.001, 100)
  end

  def rescale(input, input_low, input_high, output_low, output_high)
    return '' if input.nil?

    if input < input_low
      input = input_low;
    end

    if input > input_high

      input = input_high;
    end

    input_range = input_high - input_low;
    input_diff = input - input_low;
    output_range = output_high - output_low;
    value = (input_diff / input_range) * (output_range) + output_low
    '%.2f%%' % value
  end

  def _result_hash(result)
    histogram = ScenarioAnalysisBuilder.vote_values_from_captions(@vote_captions, result.histogram)

    row = result
            .as_json.symbolize_keys
            .slice(
              :total_votes, :abstain_votes, :negative_votes, :neutral_votes, :positive_votes,
              :seeds_assigned, :positive_seed_votes_sq, :positive_seed_votes_sum, :seed_allocation, :vote_allocation,
              :combined_allocation, :final_allocation, :quadratic
            )
            .merge(
              {
                ethelo: rescale_ethelo(result.ethelo),
                support: rescale_support(result.support),
                dissonance: rescale_dissonance(result.dissonance),
                approval: rescale_approval(result.approval),
                voting_captions: histogram.keys
              })
            .merge(histogram)

    blanks = {seeds_assigned: 0, positive_seed_votes_sq: 0, positive_seed_votes_sum: 0,
              seed_allocation: 0, vote_allocation: 0, combined_allocation: 0, final_allocation: 0}
    if result.option_category_id && result.seeds_assigned.blank?
      row = row.merge(blanks)
    end

    row
  end

  def base_stats
    {
      option_category_id: nil,
      option_category_title: nil,
      option_category_sort: '0',
      option_id: nil,
      option_sort: '0',
      option_title: nil,
      criterion_id: nil,
      criterion_title: nil,
      criterion_sort: '0',
      ethelo: nil,
      support: nil,
      dissonance: nil,
      approval: nil,
      average_weight: nil,
      sort: 0,
    }

  end

  def _calculation_stats(scenario)
    stats = []
    stats.merge!(
      scenario.calculations.map {
        |e| { title: e.title, slug: e.slug, value: e.value, format: e.format }
      }
    )

    stats.merge!(
      scenario.constraint_calculations.map {
        |e| { title: e.title, slug: e.slug, value: e.value, format: :number_with_decimals }
      }
    )
    merge
  end

  def scenario_result_for_rank(rank)
    return { scenario: nil, result: nil } if _solve_config.scenario_config.skip_solver && rank > 0
    scenario = scenario_at(rank)
    return { scenario: nil, result: nil } unless scenario
    result = scenario_result_for_scenario(scenario)
    return { scenario: nil, result: nil } unless result

    { scenario: scenario, result: result }
  end

  def scenario_result_for_scenario(scenario)
    scenario.scenario_results.find {
      |sr| sr.option_category_id.nil? and sr.option_id.nil? and sr.criterion_id.nil?
    }
  end

  def sorted_and_indexed_records(query)
    raw = query.order(:sort, :title)
    sorted = []

    raw.each_with_index { |item, index|
      item[:sort] = index
      sorted << item
    }

    sorted.map { |i| [i.id.to_s, i] }.to_h
  end

  def top_result
    @top_result ||= scenario_result_for_rank(1)
  end

  def top_scenario_option_ids
    @top_scenario_option_ids ||= (top_result[:scenario]&.options || []).map { |o| o.id.to_s }
  end

  def build_result_row(acc, result)
    values = {
      sort: '',
      option_category_sort: '00000',
      option_sort: '00000',
      criterion_sort: '00000',
    }
    stats_row = base_stats
                  .merge(_result_hash(result))
                  .merge({ type: '', top_scenario: "NO" })

    option = @options[result.option_id.to_s]
    option_category = @option_categories[result.option_category_id.to_s]

    if option.present?
      option_category = @option_categories[option.cached_option_category_id.to_s] # may not be filled in, reload to be sure

      values[:option_category_id] = option_category.id
      values[:option_category_title] = option_category.title
      values[:option_category_sort] = option_category.sort.to_s.rjust(5, '0')
      values[:option_id] = option.id
      values[:option_title] = option.title

      values[:option_sort] = option_category.sorted_options.find_index(option).to_s.rjust(5, '0')

      values[:advanced_total] = result.advanced_total || 0
      values[:advanced_votes] = result.advanced_votes || 0
      values[:type] = 'global option '

      @option_details.each do |id, option_detail|
        values["odv_#{option_detail.slug}"] = ""
      end

      option.cached_option_detail_values.to_a.each do |odv|
        option_detail = @option_details[odv.cached_option_detail_id.to_s]
        value = CachedCalculation.format_value(option_detail.admin_format_key, odv.value)
        values["odv_#{option_detail.slug}"] = value
      end

      criterion = @criteria[result.criterion_id.to_s]

      if criterion.present?
        values[:criterion_id] = result.criterion_id
        values[:criterion_title] = criterion.title
        values[:criterion_order] = criterion.sort.to_s.rjust(5, '0')
        values[:average_weight] = result.average_weight.to_f
        values[:type] = 'global criterion '
      end

      if top_scenario_option_ids.include? result.option_id.to_s
        values[:top_scenario] = "Yes"
      end

    elsif option_category.present?
      values = {
        quadratic: option_category.quadratic,
        option_category_id: option_category.id,
        option_category_title: option_category.title,
        option_category_sort: option_category.sort.to_s.rjust(5, '0'),
        average_weight: result.average_weight.to_f,
        type: 'global option_category ',
      }
    end

    unless values.nil?
      stats_row.merge!(values)
    end
    stats_row[:sort] = "#{values[:option_category_sort]}-#{values[:option_sort]}-#{values[:criterion_sort]}"
    key = "#{stats_row[:option_category_id]}-#{stats_row[:option_id]}-#{stats_row[:option_id]}-#{stats_row[:criterion_id]}"

    acc[key] = stats_row unless values[:type].nil? # eliminates duplicates, though they shouldn't exist?

    acc

  end

  def add_data_totals(stats)

    voter_count = option_category_voters(stats)
    oc_weight_info = option_category_weight_info(stats)
    c_weight_info = criterion_weight_info(stats)

    updated = stats.reduce({}) do |acc, (key, row)|
      case row[:type]
      when 'global option_category '
        row[:weights_total] = oc_weight_info[:total]
        row[:weights_count] = oc_weight_info[:count]
      when 'global criterion '
        row[:weights_total] = c_weight_info[:total]
        row[:weights_count] = c_weight_info[:count]
      when 'global option '
        row[:voter_count] = voter_count[row[:option_category_id]]
      else
        row
      end
      acc[key] = row
      acc
    end

    updated

  end

  def option_category_voters(stats)
    stats.values
      .select { |row| row[:type] == 'global option_category ' }
      .map { |row| [row[:option_category_id], row[:total_votes]] }
      .to_h
  end

  def option_category_weight_info(stats)
    valid_oc = weighted_option_categories.map { |oc| oc.id }

    values = stats.values
               .select { |row| row[:type] == 'global option_category ' && valid_oc.include?(row[:option_category_id]) }
               .map { |row| row[:average_weight] }
    { count: values.length, total: values.sum }
  end

  def criterion_weight_info(stats)
    valid_c = weighted_criteria.map { |c| c.id.to_s }

    values = stats.values
               .select { |row|
                 row[:type] == 'global criterion ' && valid_c.include?(row[:criterion_id])
               }
               .group_by { |row| row[:criterion_id] }
               .map { |id, duplicates|
                 duplicates.first[:average_weight]
               }

    { count: values.length, total: values.sum }
  end

  def result_rows
    rows ||=
      begin

        global_results = global_scenario.scenario_results
        stats = global_results.inject({}) do |acc, result|
          next if result.nil?
          build_result_row(acc, result)
        end

        stats = add_data_totals(stats)

        sorted = stats.values.sort_by { |row| row[:sort].to_s }
        sorted.each_with_index { |row, index| row[:sort] = index }
      end
  end

  def extract_columns(columns, rows)
    return [columns.values] if rows.empty?

    extracted_data = rows.map do |result_row|
      row_data = {}
      columns.each do |key, label|
        row_data[label] = result_row[key]
      end
      row_data
    end
    header_row = columns.values.zip(columns.values).to_h

    [header_row].concat(extracted_data)
  end

  def voting_summary_csv
    columns = {
      option_category_title: I18n.t('models.option_category.one'),
      option_title: I18n.t('models.option.one'),
    }

    if @decision.cached_criteria.length > 1
      columns[:criterion_title] = I18n.t('models.criterion.one')
    end

    columns[:ethelo] = I18n.t('metrics.labels.ethelo')
    columns[:support] = I18n.t('metrics.labels.support')
    columns[:dissonance] = I18n.t('metrics.labels.dissonance')
    columns[:approval] = I18n.t('metrics.labels.approval')

    unless advanced_voting_option_categories.empty?
      columns[:advanced_votes] = I18n.t('metrics.labels.advanced_votes')
    end

    columns[:total_votes] = I18n.t('metrics.labels.total_votes')
    columns[:abstain_votes] = I18n.t('metrics.labels.abstain_votes')
    columns[:negative_votes] = I18n.t('metrics.labels.negative_votes')
    columns[:positive_votes] = I18n.t('metrics.labels.positive_votes')

    @decision.voting_settings.voting_captions.each do |caption, value|
      columns[value] = value
    end

    unless weighted_option_categories.empty? && weighted_criteria.length > 1
      columns[:average_weight] = I18n.t('metrics.labels.average_weight')
    end

    columns[:top_scenario] = 'In Best Scenario'

    @option_details.each do |id, option_detail|
      columns['odv_' + option_detail.slug] = option_detail.title
    end

    extract_columns(columns, result_rows)
  end

  def self.quad_headers
    {
      option_category_title: I18n.t('models.option_category.one'),
      seeds_assigned: I18n.t('metrics.labels.seeds_assigned'),
      positive_seed_votes_sum: I18n.t('metrics.labels.positive_seed_votes_sum'),
      positive_seed_votes_sq: I18n.t('metrics.labels.positive_seed_votes_sq'),
      seed_allocation: I18n.t('metrics.labels.seed_allocation'),
      vote_allocation: I18n.t('metrics.labels.vote_allocation'),
      combined_allocation: I18n.t('metrics.labels.combined_allocation'),
      final_allocation: I18n.t('metrics.labels.final_allocation'),
    }
  end

  def quadratic_allocations_csv
    columns = self.class.quad_headers

    rows = result_rows.keep_if do |row|
      row[:option_category_id].present? && row[:quadratic]
    end

    extract_columns(columns, rows)
  end

  def average_weights_csv
    columns = {
      option_category_title: I18n.t('models.option_category.one'),
      average_weight: I18n.t('metrics.labels.average_weight'),
    }

    rows = result_rows.keep_if do |row|
      row[:average_weight].present? && row[:option_category_id].present?
    end

    extract_columns(columns, rows)

  end

  def reportable_option_categories
    @reportable_option_categories ||=
      begin
        @option_categories
          .values
          .keep_if { |coc| coc.reportable? }
          .sort_by { |coc| coc.sort }
      end

  end

  def advanced_voting_option_categories
    @advanced_voting ||= reportable_option_categories.clone.keep_if { |coc| coc.advanced_voting? }
  end

  def classic_voting_option_categories
    @classic_voting ||= reportable_option_categories.clone.keep_if { |coc| !coc.advanced_voting? }
  end

  def weighted_option_categories
    @weighted_option_categories ||= reportable_option_categories.clone.clone.keep_if { |coc| coc.apply_participant_weights }
  end

  def weighted_criteria
    @weighted_criteria ||= @decision.cached_criteria.to_a.clone
                             .keep_if { |cc| cc.apply_participant_weights }
                             .sort_by { |cc| cc.sort }
  end

end
