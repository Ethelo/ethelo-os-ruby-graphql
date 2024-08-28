module EtheloApi
  class Repo

    @structure_cache_id = nil

    def initialize(api_decision_id, local_decision_id)
      @api_decision_id = api_decision_id
      @local_decision_id = local_decision_id
      @decision = Decision.find(@local_decision_id)
      @cached_decision = CachedDecision.find_by(id: @api_decision_id)
    end

    def resync_decision!
      EtheloApi::Interface.clear_decision_structure_cache(@api_decision_id)
      rebuild_decision
    end

    def clear_participant_cache(decision_user)
      EtheloApi::Interface.clear_participant_cache(decision_user)
    end

    def clear_influent_cache(decision_user)
      EtheloApi::Interface.clear_influent_cache(decision_user)
    end

    def resync_influent_for(decision_user)
      EtheloApi::Interface.clear_influent_cache(decision_user)
      load_influent_for decision_user
    end

    def load_influent_for(decision_user)
      return if decision_user.cached_repo_id.nil?

      influent = EtheloApi::Interface.load_participant_influent(decision_user)
      EtheloApi::InfluentProcessor.new(influent.dup, decision_user).convert_to_objects
    end

    def load_participants
      EtheloApi::Interface.load_participant_list(@api_decision_id)
    end

    def load_all_influents
      EtheloApi::Interface.load_all_influents(@api_decision_id)
    end

    def load_solve_dumps(include_full = false, decision_user: nil)
      result = EtheloApi::Interface.load_solve_dumps(@api_decision_id, include_full, decision_user)
      processor = EtheloApi::SolveDumpProcessor.new(result, @decision, decision_user)
      processor.scenario_set_data
    end

    def load_solve_dump(scenario_set_id)
      return nil unless scenario_set_id.present?
      result = EtheloApi::Interface.load_solve_dump(@api_decision_id, scenario_set_id)
      processor = EtheloApi::SolveDumpProcessor.new(result, @decision, nil)
      first =  processor.scenario_set_data[:data].first || {}
      return nil unless first[:solve_dump].present?
      first
    end

    def load_decision_errors
      EtheloApi::Interface.load_decision_errors(@api_decision_id)
    end

    def load_decision_export
      EtheloApi::Interface.load_decision_export(@api_decision_id)
    end

    def load_decision_json_dump
      EtheloApi::Interface.load_decision_json_dump(@api_decision_id, @decision.group_scenario_config&.id)
    end

    def _load_and_process_scenarios(solve_config, query_vars)
      result = EtheloApi::Interface.load_scenarios(@api_decision_id, solve_config.scenario_config_id, query_vars)
      processor = EtheloApi::SolveProcessor.new(result, @decision, query_vars[:rank], query_vars[:include_global], solve_config.decision_user)
      processor.solve_result
    end

    def load_scenarios(solve_config, **query_vars)
      if query_vars[:rank].blank? && query_vars[:count].blank?
        query_vars[:count] = 10
        query_vars[:rank] = 1
      end

      if query_vars[:participant_id].nil? && query_vars[:force] != true
        expires_in = 10.seconds #(solve_config.solve_interval / 500).seconds || 10.minutes
        #  expires_in = 10.minutes if expires_in > 1.hour
        cache_key = EtheloApi::Interface.scenario_processed_cache_key(@decision.id, query_vars)
        scenarios = Rails.cache.fetch(cache_key, expires_in: expires_in) do
          result = _load_and_process_scenarios(solve_config, query_vars)
          result[:cache_save] = Time.current.to_i
          result
        end
        scenarios[:cache_load] = Time.current.to_i
        scenarios
      else
        result = _load_and_process_scenarios(solve_config, query_vars)
        if result[:meta][:status] == "success"
          @decision.update_last_solved_at(result[:meta][:updated_at])
        end
        result
      end
    end

    def solve_decision(solve_config, force = false, save_dump = false)
      return false unless solve_config.scenario_config.present?
      EtheloApi::Interface.solve_decision(
        @api_decision_id,
        solve_config.scenario_config_id,
        solve_config.published,
        solve_config.participant_id,
        force,
        save_dump
      )
    end

    def publish_decision
      EtheloApi::Interface.cache_decision(@api_decision_id)
      EtheloApi::Interface.cache_scenario_config(@api_decision_id, @decision.group_scenario_config&.id)
      EtheloApi::Interface.cache_scenario_config(@api_decision_id, @decision.participant_scenario_config&.id)
      rebuild_decision
      publish_status
    end

    def publish_status
      participant_config = @decision.participant_scenario_config
      group_config = @decision.group_scenario_config
      return false unless participant_config.id && group_config.id
      status = EtheloApi::Interface.load_decision_publish_status(@api_decision_id, group_config.id, participant_config.id)
      return false unless status.dig(:query_result, :meta, :successful)
      SolveConfig.create_for(@decision, nil, true).schedule_solve

      results = status.dig(:query_result, :published) || {}
      unpublished = results.keep_if { |_key, value| !value }
      unpublished.length === 0
    end

    def rebuild_decision
      @structure = EtheloApi::Interface.load_decision_structure(@api_decision_id)
      return false unless @structure.dig(:query_result, :meta, :successful)
      @structure_cache_id = DateTime.parse(@structure.dig(:query_result, :meta, :completed_at)).to_i
      decision_cache_id = @cached_decision&.cache_id&.to_i || 0
      return if decision_cache_id > 0 && decision_cache_id == @structure_cache_id
      EtheloApi::StructureProcessor.new(@structure, @decision, @structure_cache_id).sync_data
      nil # we don't use the result directly
    end

    def save_to_api(object, upsert = false)
      if upsert
        EtheloApi::Interface.upsert_object(object)
      else
        if object.persisted?
          EtheloApi::Interface.update_object(object)
        else
          EtheloApi::Interface.create_object(object)
        end
      end
    end

    def delete_from_api(object)
      EtheloApi::Interface.delete_object(object)
    end

    def delete_decision
      EtheloApi::Interface.delete_decision(@decision)
    end

    def self.create_decision(cached_decision)
      EtheloApi::Interface.create_object(cached_decision)
    end

  end
end
