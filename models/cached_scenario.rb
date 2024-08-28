class CachedScenario < ActiveModelSerializers::Model
  attributes :id, :api_id,
    :updated_at, :status, :meta,
    :decision, :decision_id, :cached_decision_id,
    :decision_user, :decision_user_id, :participant_id,
    :scenario_set, :scenario_set_id,
    :global, :quadratic, :minimize, :collective_identity,
    :options, :scenario_results, :rank,
    :published, :calculations, :constraint_calculations

end
