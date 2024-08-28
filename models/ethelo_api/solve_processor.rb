module EtheloApi

  class SolveProcessor
    include ActionView::Helpers::DateHelper

    def initialize(result, decision, scenario_rank = nil, include_global = false, decision_user = nil)
      @raw = result.clone
      @cached_at = @raw.dig(:query_result, :meta, :completed_at)
      @scenario_set = @raw.dig(:query_result, :scenario_sets)&.first || {}
      @updated_at = @scenario_set[:updated_at] || @cached_at
      @published = @scenario_set.dig(:published)
      @scenario_set_id = @scenario_set[:id]
      @participant_id = @scenario_set[:participant_id]
      solve_config = decision.cached_scenario_configs.where(id: @scenario_set[:scenario_config_id]).first
      @quadratic = solve_config&.quadratic || false
      @include_global = include_global
      @decision = decision
      @scenario_rank = scenario_rank.nil? ? 1 : scenario_rank
      @decision_user = decision_user
    end

    def raw_results
      @raw
    end

    def solve_result
      {
        raw: @raw.to_json,
        meta: meta,
        dump: solve_dump,
        dump_id: solve_dump_id,
        data: convert_to_scenarios,
      }
    end

    def solve_dump
      @scenario_set['solve_dump'] || {}
    end

    def solve_dump_id
      if( dump_id = @scenario_set.dig(:dump_id, :id) )
        dump_id
      else
        nil
      end
    end

    def add_duration_meta(meta)
      start_time = DateTime.parse(@scenario_set[:engine_start]) rescue nil
      end_time = DateTime.parse(@scenario_set[:engine_end]) rescue nil
      return meta unless start_time && end_time

      duration_seconds = (end_time.to_time - start_time.to_time).to_i

      meta[:started] = start_time.to_s
      meta[:duration_seconds] = duration_seconds
      meta[:duration_words] = distance_of_time_in_words(Time.current, Time.current + duration_seconds, include_seconds: true)
      meta

    end

    def meta
      @meta ||=
        begin
          base = {
            count: @scenario_set[:count],
            date: @scenario_set[:updated_at],
            status: @scenario_set[:status],
            participant_id: @scenario_set[:participant_id],
            published: @scenario_set[:published],
            engine_id: @scenario_set_id,
            cached_at: @cached_at,
            updated_at: @updated_at,
          }
          add_duration_meta(base)
        end
    end

    def convert_to_scenarios
      scenarios = []

      if @scenario_rank > 0

        ranked = @scenario_set[:ranked_scenarios] || []
        filtered = ranked
                   .reject {|s|
                     s[:scenario_results].nil? }
                   .sort_by {|s|
                     s[:scenario_results][:ethelo]
                   }.reverse

        scenarios << _prepare_scenario(filtered&.shift, @scenario_rank)
        i = 1
        filtered.each do |scenario|
          scenarios << _prepare_scenario(scenario, @scenario_rank + i)
          i = i + 1
        end
      end

      scenarios << _prepare_scenario(@scenario_set[:summary_scenarios]&.first, 0, @scenario_set[:summary_results]) if @include_global
      scenarios.compact
    end

    def unavailable_scenario(rank)
      scenario = {
        id: nil,
        rank: rank,
        options: [],
        scenario_results: [],
        calculations: [],
        constraint_calculations: [],
        published: @published,
        updated_at: @updated_at,
        status: @scenario_set[:status],
        meta: meta,
      }
      scenario = _add_common_attributes(scenario)
      scenario[:scenario_set_id] = @scenario_set_id
      scenario = _swap_id(scenario, rank)
      CachedScenario.new(scenario)
    end

    def _add_common_attributes(record)
      record[:decision_id] = @decision.id
      record[:decision] = @decision
      record[:cached_decision_id] = @decision.cached_decision.id
      record[:participant_id] = @participant_id
      record[:decision_user] = @decision_user
      record[:updated_at] = @updated_at

      record
    end

    def _swap_id(record, new_id)
      record[:api_id] = record[:id]
      record[:id] = @decision_user.present? ? "#{new_id}-#{@decision_user.id}" : new_id
      record[:id] = record[:status] === 'pending' ? "#{record[:id]}-#{record[:status]}" : record[:id]
      record
    end

    def auto_balance_option_id
      @aboi ||= @decision.sidebars_settings.auto_balance_option(false)&.id
    end

    def _scenario_options(scenario)
      options = scenario[:options].map { |o| o.is_a?(Hash) ? CachedOption.new(o) : o } if scenario[:options].present?
      options = [] if options.nil?

      options.delete_if do |option|
        auto_balance_option_id.present? && option.id.to_i === auto_balance_option_id
      end
    end

    def _prepare_scenario(scenario, rank, extra_results=[])
      return unavailable_scenario(rank) if scenario.nil?
      scenario = _add_common_attributes(scenario)
      scenario = _swap_id(scenario, rank)
      scenario[:meta] = meta
      scenario[:quadratic] = @quadratic
      scenario[:published] = @published
      scenario[:rank] = rank
      scenario[:scenario_set_id] = @scenario_set_id
      scenario[:status] = scenario[:status]
      scenario[:options] = _scenario_options(scenario)

      results = [scenario[:scenario_results]].concat(extra_results).compact

      scenario[:scenario_results] = _prepare_results(results, scenario[:id], scenario[:api_id])

      scenario[:calculations] = _prepare_calculations(scenario)
      scenario[:constraint_calculations] = _prepare_constraint_calculations(scenario)
      scenario.delete :calculated_values
      CachedScenario.new(scenario)
    end

    def _parse_decimal(value)
      return nil if value.nil?
      BigDecimal(value, 5).round(5, :half_up)
    end

    def calculation_index
      @calculation_index ||= @decision.cached_calculations.to_a.map {|c| [c.id, c]}.to_h
    end

    def _prepare_calculations(scenario)
      return [] unless scenario[:calculated_values].present?
      result = scenario[:calculated_values].map do |record|
        next nil if record[:is_constraint]
        calculation = calculation_index[record[:calculation_id].to_i]
        next nil unless calculation.present?

        record[:api_id] = record[:id]
        record[:id] = "scalc-#{scenario[:id]}-#{calculation.slug}"
        record[:decision_id] = @decision.id
        record[:cached_decision_id] = @decision.cached_decision.id
        record[:calculation] = calculation
        record[:scenario_id] = scenario[:id]
        record[:scenario_api_id] = scenario[:api_id]
        record[:scenario] = maybe_has_one(record, :scenario, CachedScenario)

        CachedScenarioCalculation.new(record)
      end
      result.compact
    end

    def constraint_index
      @constraint_index ||= @decision.cached_constraints.to_a.map {|c| [c.id, c]}.to_h
    end

    def _prepare_constraint_calculations(scenario)
      return [] unless scenario[:calculated_values].present?
      result = scenario[:calculated_values].map do |record|
        next nil unless record[:is_constraint] && record[:constraint_id]
        constraint = constraint_index[record[:constraint_id].to_i]
        next nil unless constraint.present?

        record[:api_id] = record[:id]
        record[:id] = "sconst-#{scenario[:id]}-#{constraint.slug}"
        record[:decision_id] = @decision.id
        record[:cached_decision_id] = @decision.cached_decision.id
        record[:constraint] = constraint
        record[:scenario_id] = scenario[:id]
        record[:scenario_api_id] = scenario[:api_id]
        record[:scenario] = maybe_has_one(record, :scenario, CachedScenario)

        CachedScenarioConstraintCalculation.new(record)
      end

      result.compact
    end

    def _prepare_results(records, scenario_id=nil, scenario_api_id=nil)
      return [] if records.nil?
      results = records.map do |raw_record|
        if raw_record.respond_to? :keys
          record = _add_common_attributes(raw_record)

          record[:average_weight] = _parse_decimal(raw_record[:average_weight])
          record[:ethelo] = _parse_decimal(raw_record[:ethelo])
          record[:approval] = _parse_decimal(raw_record[:approval])
          record[:support] = _parse_decimal(raw_record[:support])
          record[:dissonance] = _parse_decimal(raw_record[:dissonance])

          record[:scenario_id] = scenario_id
          record[:scenario_api_id] = scenario_api_id
          record[:scenario] = maybe_has_one(record, :scenario, CachedScenario)

          record = update_advanced_stats(record)
          record = _swap_id(record, _create_result_id(record))
          CachedScenarioResult.new(record)
        else
          record # catch case where double processing occurs somehow?
        end
      end

      results = results.delete_if do |record|
        record.nil? || (record.option_id && auto_balance_option_id && record.option_id.to_i == auto_balance_option_id)
      end

      strip_duplicate_results(results)
        .sort_by { |result| result.id } # not necessary but makes it easier to read when debugging
    end

    def update_advanced_stats(record)
      if record[:advanced_stats].present?
        record[:advanced_total] = record[:advanced_stats][1]
        record[:advanced_votes] = record[:advanced_stats][0]
      else
        record[:advanced_total] = 0
        record[:advanced_votes] = 0
      end

      record.delete(:advanced_stats)
      record
    end

    # we could have multiple results with the same relationship based id,
    # this cleans them up so we only ever have one.
    def strip_duplicate_results(results)
      Hash[results.collect { |item| [item.id, item] }].values
    end

    def maybe_has_one(record, key, class_object)
      id_field = "#{key}_id".to_sym
      if record[id_field].present?
        class_object.new({id: record[id_field]})
      else
        nil
      end
    end

    # this id identifies unique relationship combinations, as those are what the frontend needs
    # to allow new updates to overwrite old ones
    def _create_result_id(result)
      id = [
        'sr',
        result[:decision_id],
        result[:decision_user]&.id,
        result[:scenario_id],
        result[:option_category_id],
        result[:option_id],
        result[:criterion_id]
      ].join('-')
      id
    end

  end
end
