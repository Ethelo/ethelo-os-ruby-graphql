module EtheloApi

  class StructureProcessor

    include SemanticLogger::Loggable

    def initialize(result, decision, cache_id)
      @result = result[:query_result]
      @decision = decision
      @cached_decision = decision.cached_decision
      @cached_decision_cache_id = @cached_decision&.cache_id&.to_i || 0
      @cache_id = cache_id
    end

    def sync_data
      return if @cached_decision_cache_id > 0 && @cached_decision_cache_id == @cache_id.to_i

      sync_decision(@result[:decision])

      sync_all_children
    end

    def sync_all_children
      # order is important, dependencies must be loaded before dependants
      sync_children(CachedOptionDetail, @result[:option_details])
      sync_children(CachedOptionCategory, @result[:option_categories], with_options: false)
      sync_children(CachedOption, @result[:options])
      sync_children(CachedOptionCategory, @result[:option_categories], with_options: true) # resync
      sync_children(CachedOptionDetailValue, @result[:options])
      sync_children(CachedOptionFilter, @result[:option_filters])
      sync_children(CachedVariable, @result[:variables])
      sync_children(CachedCriterion, @result[:criterias])
      sync_children(CachedCalculation, @result[:calculations])
      sync_children(CachedCalculationVariable, @result[:calculations])
      sync_children(CachedConstraint, @result[:constraints])
      sync_children(CachedScenarioConfig, @result[:scenario_configs])

    end

    def sync_decision(data)
      data.merge({
        cache_id: @cache_id,
        created_at: data[:inserted_at]
      })
      data.delete :inserted_at

      CachedDecision.upsert(data)
    end

    def sync_children(cached_class, data, settings = {})
      data = [] if data.nil?
      data.each do |row|
        to_sync = prepare_for_sync(row)
        result = cached_class.upsert_from_graphql(to_sync, settings)
        unless result

          logger.info("upsert fail #{cached_class.name}  #{result.inspect} #{to_sync.to_json}")
        end
      end

      delete_expired_children(cached_class)
    end

    def delete_expired_children(classname)
      classname
        .where({cached_decision_id: @cached_decision.id})
        .where.not({cache_id: @cache_id})
        .delete_all
    end

    def prepare_for_sync(graphql_hash)
      updated = graphql_hash.merge({
        cached_decision_id: @cached_decision.id,
        decision_id: @decision.id,
        cache_id: @cache_id,
        created_at: graphql_hash[:inserted_at]
      })
      updated.delete :inserted_at
      updated
    end
  end

end
