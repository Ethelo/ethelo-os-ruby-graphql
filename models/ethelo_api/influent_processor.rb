module EtheloApi
  class InfluentProcessor

    def initialize(result, decision_user)
      @result = result
      @influent_id = result[:id]
      @decision_user = decision_user
      @decision = @decision_user.decision
      @participant_id = @decision_user.cached_repo_id
    end

    def convert_to_objects
      influent = @result
      influent[:option_category_range_votes] = prepare_records(influent[:option_category_range_votes], CachedOptionCategoryRangeVote)
      influent[:bin_votes] = prepare_records(influent[:bin_votes], CachedBinVote)
      influent[:option_category_bin_votes] = prepare_records(influent[:option_category_bin_votes], CachedOptionCategoryBinVote)
      influent[:option_category_weights] = prepare_records(influent[:option_category_weights], CachedOptionCategoryWeight)
      influent[:criterion_weights] = prepare_records(influent[:criterion_weights], CachedCriterionWeight)
      influent
    end

    def prepare_records(records, class_object)
      return [] if records.nil?
      records.map do |record|
        record[:delete] = record[:delete_vote]
        record.delete(:delete_vote)
        record[:decision_user] = @decision_user
        record[:decision_user_id] = @decision_user.id
        record[:decision_id] = @decision.id
        record[:decision] = @decision
        record[:cached_decision_id] = @decision.cached_decision.id
        record[:participant_id] = @participant_id unless record[:participant_id].present?
        class_object.new(record)
      end
    end
  end

end
