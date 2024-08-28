class CachedScenarioCalculation < ActiveModelSerializers::Model
  attributes :id, :api_id,
    :value, :is_constraint, :name, :sort,
    :inserted_at, :updated_at,
    :constraint_id, :constraint,
    :calculation_id, :calculation,
    :decision, :decision_id, :cached_decision_id,
    :scenario, :scenario_id, :scenario_api_id

  def slug
    calculation&.slug
  end

  def title
    calculation&.title
  end

  def personal_results_title
    calculation&.personal_results_title
  end

  def format
    calculation&.admin_format_key
  end

  def sort
    calculation&.sort
  end

  def public
    (calculation&.public).present?
  end

end
