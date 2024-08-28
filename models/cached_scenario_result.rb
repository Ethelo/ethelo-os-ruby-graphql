class CachedScenarioResult < ActiveModelSerializers::Model
  attributes :id, :api_id,
    :updated_at,

    :ethelo, :approval, :support, :dissonance, :average_weight,
    :histogram, :advanced_total, :advanced_votes,
    :total_votes, :negative_votes, :neutral_votes, :positive_votes, :abstain_votes,

    :seeds_assigned, :positive_seed_votes_sq, :positive_seed_votes_sum, :seed_allocation, :vote_allocation,
    :combined_allocation, :final_allocation, :quadratic,

    :scenario, :scenario_id, :scenario_api_id,
    :criterion, :criterion_id,
    :option, :option_id,
    :option_category, :option_category_id,
    :decision, :decision_id, :cached_decision_id,
    :decision_user, :decision_user_id, :participant_id

end
