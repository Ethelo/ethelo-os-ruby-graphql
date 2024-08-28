class CachedScenarioConstraintCalculation < ActiveModelSerializers::Model
  attributes :id, :api_id,
    :value, :is_constraint, :name, :public,
    :inserted_at, :updated_at,
    :constraint_id, :constraint,
    :calculation_id, :calculation,
    :decision, :decision_id, :cached_decision_id,
    :scenario, :scenario_id, :scenario_api_id

  def slug
    constraint&.slug
  end

  def title
    constraint&.title
  end

  def public
    (calculation&.public).present?
  end

end
