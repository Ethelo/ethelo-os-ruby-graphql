module EtheloApi
  # Note: Decision Id is the api decision id, not the local id
  class Interface
    class << self

      def decision_cache_key(decision_id)
        "#{decision_id}_structure"
      end

      def participant_cache_key(decision_user)
        "#{decision_user.id}_participant"
      end

      def influent_cache_key(decision_user)
        "#{decision_user.id}_influent"
      end

      def clear_decision_structure_cache(decision_id)
        Rails.cache.delete(decision_cache_key(decision_id))
      end

      def clear_participant_cache(decision_user)
        Rails.cache.delete(participant_cache_key(decision_user))
      end

      def clear_influent_cache(decision_user)
        Rails.cache.delete(influent_cache_key(decision_user))
      end

      def check_decision_present(decision_id)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_DECISION_ID, { decision_id: decision_id })
        EtheloApi::QueryProcessor.new(query_result).process
      end

      def clear_decision_scenario_cache(decision_id, rank)
        "#{decision_cache_key(decision_id)}_#{rank}"
      end

      def load_decision_structure(decision_id)
        # expire time will need tweaking but should be as small as possible
        Rails.cache.fetch(decision_cache_key(decision_id), expires_in: 5.minutes) do
          query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_DECISION_STRUCTURE, { decision_id: decision_id })
          EtheloApi::QueryProcessor.new(query_result).process
        end
      end

      def load_decision_export(decision_id)
        query_result = EtheloApi::Runner.run_query(
          EtheloApi::Queries::LOAD_DECISION_EXPORT, { decision_id: decision_id }
        )
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        parsed.dig(:query_result, :decision, :export)
      end

      def load_decision_json_dump(decision_id, scenario_config_id, participant_id = nil, cached = false)
        query_result = EtheloApi::Runner.run_query(
          EtheloApi::Queries::LOAD_DECISION_JSON_DUMP,
          {
            decision_id: decision_id,
            scenario_config_id: scenario_config_id,
            participant_id: participant_id,
            cached: cached,
          }
        )
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        parsed.dig(:query_result, :decision, :json_dump)
      end

      def load_decision_votes_histogram(decision_id)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_DECISION_VOTES_HISTOGRAM, { decision_id: decision_id })
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        result = parsed.dig(:query_result, :decision, :votes_histogram) || []
      end

      def load_decision_publish_status(decision_id, group_config_id, participant_config_id)
        variables = { decision_id: decision_id, group_config_id: group_config_id, participant_config_id: participant_config_id }
        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_DECISION_PUBLISH_STATUS, variables)
        EtheloApi::QueryProcessor.new(query_result).process
      end

      def load_decision_errors(decision_id)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_DECISION_ERRORS, { decision_id: decision_id })
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        parsed.dig(:query_result, :scenario_sets) || []
      end

      def load_solve_dumps(decision_id, include_full = false, decision_user = nil)
        variables = { decision_id: decision_id, participant_id: decision_user&.cached_repo_id, full_dump: false }
        variables[:full_dump] = include_full

        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_SOLVE_DUMPS, variables)
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        parsed[:query_result] || {}
      end

      def load_solve_dump(decision_id, scenario_set_id)
        variables = { decision_id: decision_id, scenario_set_id: scenario_set_id, full_dump: true }
        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_SOLVE_DUMPS, variables)
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        parsed[:query_result] || {}
      end

      def scenarios_query(decision_id, scenario_config_id, **query_vars)
        query_result = EtheloApi::Runner.run_query(
          EtheloApi::Queries::LOAD_RANKED_SCENARIO,
          {
            decision_id: decision_id,
            participant_id: query_vars[:participant_id],
            scenario_config_id: scenario_config_id,
            cached: query_vars[:cached],
            rank: query_vars[:rank],
            include_ranked: query_vars[:rank].to_i > 0,
            include_global: query_vars[:include_global] || query_vars[:rank] === 0,
            status: query_vars[:participant_id].present? ? nil : :success,
            include_dump: !!query_vars[:include_dump],
            count: query_vars[:count],
          }
        )
        EtheloApi::QueryProcessor.new(query_result).process
      end

      def scenario_load_cache_key(decision_id, query_vars)
        key_parts = [
          decision_cache_key(decision_id),
          query_vars[:rank] || ' ',
          query_vars[:include_global] ? 1 : 0,
          query_vars[:include_ranked] ? 1 : 0,
          query_vars[:include_dump] ? 1 : 0,
          query_vars[:count] || 1,
          query_vars[:cached] ? 1 : 0,
        ]
        key_parts.join('_')
      end

      def scenario_processed_cache_key(decision_id, query_vars)
        key_parts = [
          decision_cache_key(decision_id),
          'processed',
          query_vars[:rank] || ' ',
          query_vars[:include_global] ? 1 : 0,
          query_vars[:include_ranked] ? 1 : 0,
          query_vars[:include_dump] ? 1 : 0,
          query_vars[:count] || 1,
          query_vars[:cached] ? 1 : 0,
        ]
        key_parts.join('_')
      end

      def load_scenarios(decision_id, scenario_config_id, **query_vars)
        if query_vars[:participant_id].nil?
          result = Rails.cache.fetch(scenario_load_cache_key(decision_id, query_vars), expires_in: 5.seconds) do
            scenarios_query(decision_id, scenario_config_id, **query_vars)
          end
          result
        else
          scenarios_query(decision_id, scenario_config_id, **query_vars)
        end
      end

      def copy_decision(decision_id, title = nil, slug = nil, info = nil)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations::COPY_DECISION, { id: decision_id, title: title, slug: slug, info: info })
        EtheloApi::QueryProcessor.new(query_result).process
      end

      def import_decision(export, title = nil, slug = nil, info = nil)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations::IMPORT_DECISION, { export: export, title: title, slug: slug, info: info })
        EtheloApi::QueryProcessor.new(query_result).process
      end

      def solve_decision(decision_id, scenario_config_id, use_cache, participant_id, force, save_dump)
        variables = {
          decision_id: decision_id, participant_id: participant_id,
          scenario_config_id: scenario_config_id,
          use_cache: use_cache, force: force, save_dump: save_dump
        }
        EtheloApi::Runner.run_query(
          EtheloApi::Mutations::SOLVE_DECISION,
          variables,
          participant_id ? :default : :group_results
        )
        nil # we don't care about the direct response, instead we query scenarios
      end

      def cache_decision(decision_id)
        variables = { decision_id: decision_id }
        result = EtheloApi::Runner.run_query(EtheloApi::Mutations::CACHE_DECISION, variables)
        nil # we don't care about the direct response, instead we query publish status
      end

      def cache_scenario_config(decision_id, scenario_config_id)
        variables = { decision_id: decision_id, id: scenario_config_id }
        result = EtheloApi::Runner.run_query(EtheloApi::Mutations::CACHE_SCENARIO_CONFIG, variables)
        nil # we don't care about the direct response, instead we query publish status
      end

      def rename_cached(variables)
        variables.map { |k, v| [k.to_s.gsub('cached_', ''), v] }.to_h
      end

      def update_object(object)
        mutate_object('UPDATE', object)
      end

      def create_object(object)
        mutate_object('CREATE', object)
      end

      def upsert_object(object)
        mutate_object('UPSERT', object)
      end

      def mutate_object(mode, object)
        variables = rename_cached(object.attributes_for_graphql)
        variables = variables.slice(*EtheloApi::Mutations.field_list_for(mode, object))
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations.query_for(mode, object), variables)
        EtheloApi::MutationProcessor.new(object, query_result).process
      end

      def delete_object(object)
        variables = rename_cached(object.attributes_for_graphql)
        variables = variables.slice(*EtheloApi::Mutations.field_list_for('DELETE', object))
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations.query_for('DELETE', object), variables)
        EtheloApi::MutationProcessor.new(object, query_result).process
      end

      def delete_decision(decision)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations::DELETE_DECISION, { id: decision.cached_decision_id })
        EtheloApi::DeleteDecisionProcessor.new(query_result, decision).process
      end

      def create_participant(decision_user, weighting = nil)
        params = { decision_id: decision_user.decision.cached_decision_id }
        params[:weighting] = weighting.nil? ? 1.0 : weighting
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations::CREATE_PARTICIPANT, params)
        EtheloApi::MutationProcessor.new(decision_user, query_result).process
      end

      def update_participant(decision_user, weighting = nil)
        params = { decision_id: decision_user.decision.cached_decision_id, id: decision_user.cached_repo_id }
        params[:weighting] = weighting.nil? ? decision_user.influence : weighting
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations::UPDATE_PARTICIPANT, params)
        EtheloApi::MutationProcessor.new(decision_user, query_result).process
      end

      def delete_participant(decision_user)
        params = { decision_id: decision_user.decision.cached_decision_id, id: decision_user.cached_repo_id }
        query_result = EtheloApi::Runner.run_query(EtheloApi::Mutations::DELETE_PARTICIPANT, params)
        EtheloApi::MutationProcessor.new(decision_user, query_result).process
      end

      def load_participant_influent(decision_user)
        Rails.cache.fetch(influent_cache_key(decision_user), expires_in: 1.minutes) do
          query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_PARTICIPANT_INFLUENT, {
            decision_id: decision_user.decision.cached_decision.id,
            participant_id: decision_user.cached_repo_id
          })
          parsed = EtheloApi::QueryProcessor.new(query_result).process
          participant_list = parsed.dig(:query_result, :participants) || []
          result = participant_list&.first || { id: nil }
          result[:cache_id] = parsed.dig(:meta, :completed_at).to_i
          result
        end
      end

      def load_all_influents(decision_id)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_ALL_INFLUENTS, {
          decision_id: decision_id,
        })
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        parsed.dig(:query_result, :participants) || []
      end

      def load_participant_list(decision_id)
        query_result = EtheloApi::Runner.run_query(EtheloApi::Queries::LOAD_PARTICIPANT_LIST, {
          decision_id: decision_id,
        })
        parsed = EtheloApi::QueryProcessor.new(query_result).process
        result = parsed.dig(:query_result, :participants) || []
        result
      end

    end

  end
end
