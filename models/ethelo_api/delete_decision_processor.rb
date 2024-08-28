module EtheloApi
  class DeleteDecisionProcessor < QueryProcessor

    def initialize(result, decision)
      super(result)
      @decision = decision
    end

    def process
      if @result[:data].present?
        result = @result[:data].values.first
        success = result[:successful] || result.dig(:messages, 0, :message) == 'does not exist'
      else
        success = false
      end

      if success
        delete_data
      else
        #TODO better error handling on bad graphql
        logger.error(@result[:messages].to_a.join[', '])
        @decision.errors.add(:base, 'Unexpected error, please try again')
      end

      success
    end

    def delete_data
      child_classes.each { |classname| delete_children(classname) }
      true
    end

    def delete_children(classname)
      classname
        .where({decision_id: @decision.id})
        .delete_all
    end

    def child_classes
      # order is important, dependencies must be loaded before dependants
      [
        DecisionUser,
        CachedOptionCategory,
        CachedOptionDetail,
        CachedOption,
        CachedOptionDetailValue,
        CachedOptionFilter,
        CachedVariable,
        CachedCriterion,
        CachedCalculation,
        CachedCalculationVariable,
        CachedConstraint,
        CachedScenarioConfig,
      ]
    end

  end

end
