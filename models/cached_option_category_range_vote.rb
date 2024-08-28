class CachedOptionCategoryRangeVote < ActiveModelSerializers::Model
  attributes :id, :updated_at,
    :low_option_id, :option_category_id, :high_option_id, :delete,
    :decision_user_id, :decision_user, :participant_id,
    :decision_id, :cached_decision_id, :decision

  def id
    "ocrv-#{decision_user_id}-#{option_category_id}"
  end

  def attributes_for_graphql
    attrs = self.attributes
    attrs[:low_option_id] = 0 if self.delete
    attrs[:high_option_id] = 0 if self.delete
    attrs
  end
  def mutation_mode_name(mode)
    mode.upcase
  end

  def graphql_object_name()
    self.class.name.underscore.gsub('cached_', '').upcase
  end

end
