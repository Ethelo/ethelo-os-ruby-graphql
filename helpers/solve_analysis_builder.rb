class SolveAnalysisBuilder < ScenarioAnalysisBuilder

  def reportable_options
    @ro ||= @options.select { |_k, o| o.reportable? }
  end

  def calculation_columns
    calculations = @decision.cached_calculations.sort_by { |c| "#{c.sort} + #{c.title}" }

    row = {}
    calculations.each do |sc|
      row[sc.slug] = {slug: sc.slug, title: sc.title}
    end
    row
  end

  def option_columns
    columns = {}

    @option_categories.values.each do |option_category|
      if option_category.advanced_voting?
        columns[option_category.slug] = {slug: option_category.slug, title: option_category.title}
      else
        oc_options = reportable_options.values.keep_if { |option| option.cached_option_category_id == option_category.id }

        oc_options.each do |option|
          columns[option.slug] = {slug: option.slug, title: option.title}
        end
      end

    end

    columns
  end

  def scenario_comparison
    @sc_rows ||=
      begin
        scenarios = scenario_list.clone.keep_if do |scenario|
          scenario.rank && scenario.rank.to_i > 0 && scenario.options.length > 0
        end
        scenarios.map do |scenario|
          _build_scenario_row(scenario)
        end.compact
      end
  end

  def option_comparison
    comparison = {}

    scenario_comparison.each do | scenario_row |
      option_columns.each do |slug, values|
        row = comparison[slug] || {}
        row[:title] = values[:title]
        row[scenario_row[:search_rank]] = scenario_row[slug]
        comparison[slug] = row
      end
    end

    comparison.values
  end

  def _build_scenario_row(scenario)
    scenario_result = scenario_result_for_scenario(scenario)
    return nil if scenario_result.nil?
    row = {
      search_rank: "Scenario #{scenario.rank}",
      rank: scenario.rank,
      ethelo: nil,
      support: nil,
      dissonance: nil,
      approval: nil,
    }

    scenario_result = scenario_result_for_scenario(scenario)
    row = row.merge(_result_hash(scenario_result)) unless scenario_result.nil?

    scenario_options = scenario.options.map { |o| o.id.to_s } || []

    _add_option_columns(row, scenario_options)
    _add_calculation_columns(row, scenario)
    row
  end

  def _add_option_columns(row, scenario_options)
    @option_categories.values.each do |option_category|
      oc_options = reportable_options.values.keep_if { |option| option.cached_option_category_id == option_category.id }

      if option_category.advanced_voting?
        option = oc_options.find { |option| scenario_options.include? option.id.to_s }

        option_details = option_category.options_with_detail_values

        row[option_category.slug] = option_details[option&.id]

      else
        oc_options.each do |option|
          row[option.slug] = scenario_options.include? option.id.to_s
        end
      end

    end
    row
  end

  def _add_calculation_columns(row, scenario)
    calculations = scenario.calculations.sort_by { |c| c.sort }

    calculations.each do |sc|
      row[sc.slug] = CachedCalculation.format_value(sc.format, sc.value)
    end

  end

end
