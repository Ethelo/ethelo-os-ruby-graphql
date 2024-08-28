class CachedCriterionWeight < ActiveModelSerializers::Model
  attributes :id, :updated_at,
    :criterion_id, :weighting,
    :decision_user_id, :decision_user, :participant_id,
    :decision_id, :cached_decision_id, :decision,
    :delete

  def attributes_for_graphql
    attrs = self.attributes
    attrs[:weighting] = 0 if self.delete
    attrs
  end

  def mutation_mode_name(mode)
    mode.upcase
  end

  def graphql_object_name()
    self.class.name.underscore.gsub('cached_', '').upcase
  end

end
