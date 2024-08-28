module EtheloApi

  class SolveDumpProcessor
    include ActionView::Helpers::DateHelper

    def initialize(result, decision, decision_user = nil)
      @raw = result.clone
      @scenario_sets = @raw.dig(:scenario_sets) || []
      @decision = decision
      @decision_user = decision_user
    end

    def raw_results
      @raw
    end

    def scenario_set_data
      d = {
        raw: @raw.to_json,
        data: prepare_scenario_sets,
      }
    end

    def _add_duration(scenario_set)
      start_time = DateTime.parse(scenario_set[:engine_start]) rescue nil
      end_time = DateTime.parse(scenario_set[:engine_end]) rescue nil
      scenario_set.delete(:engine_start)
      scenario_set.delete(:engine_end)
      duration = { started: start_time, duration_seconds: nil, duration_words: nil, ended: end_time }
      unless start_time && end_time
        return scenario_set.merge(duration)
      end
      duration_seconds = (end_time.to_time - start_time.to_time).to_i

      duration[:duration_seconds] = duration_seconds
      duration[:duration_words] = distance_of_time_in_words(Time.current, Time.current + duration_seconds, include_seconds: true)
      scenario_set.merge(duration)
    end

    def _add_common_attributes(record)
      record[:decision_id] = @decision.id
      record[:cached_decision_id] = @decision.cached_decision.id
      record
    end

    def prepare_scenario_sets
      prepared = @scenario_sets.map do |scenario_set|
        scenario_set = _add_common_attributes(scenario_set)
        scenario_set = _add_duration(scenario_set)
        if( dump_id = scenario_set.dig(:dump_id, :id) )
          scenario_set[:dump_id] = dump_id
        else
          scenario_set[:dump_id] = nil
        end

        if scenario_set[:error] == "failed to discover satisfaction range"
          scenario_set[:error] = "Unable to solve decision. Please check your constraints and XOR topics"
        end
        preproc = [ "Decision Mismatched for Preproc Data", "Preproc Data for older version detected"]
        if preproc.include? scenario_set[:error]
          scenario_set[:error] = "Decision Out of Date, please Re-Publish"
        end

        inserted_at = DateTime.parse(scenario_set[:inserted_at]) rescue nil
        scenario_set[:inserted_at] = inserted_at if inserted_at.present?
        updated_at = DateTime.parse(scenario_set[:updated_at]) rescue nil
        scenario_set[:updated_at] = updated_at if updated_at.present?

        scenario_set
      end
      prepared || []
    end
  end
end
