class CachedOptionCategoryBinVote < ActiveModelSerializers::Model
  attributes :id, :updated_at,
    :bin, :option_category_id, :criterion_id, :delete,
    :decision_user_id, :decision_user, :participant_id,
    :decision_id, :cached_decision_id, :decision

  def id
    "ocbv-#{decision_user_id}-#{option_category_id}-#{criterion_id}"
  end

  def attributes_for_graphql
    self.attributes
  end

  def mutation_mode_name(mode)
    mode.upcase
  end

  def graphql_object_name()
    self.class.name.underscore.gsub('cached_', '').upcase
  end

end
