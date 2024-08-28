class DecisionUser < ApplicationRecord

  belongs_to :decision
  validates :decision, presence: true

  attribute :cached_repo_id, :integer

  attribute :influence, :float, default: 1.0, precision: 5
  validates :influence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99999.99 }

  def create_participant!
    return unless persisted?
    unless cached_repo_id.present? && cached_repo_id.to_i > 0
      decision_user = EtheloApi::Interface.create_participant(self, self.influence)
      decision_user.save
      EtheloApi::Interface.clear_participant_cache(self)
    end
  end

  def update_participant
    return unless persisted?
    if cached_repo_id.present? && cached_repo_id.to_i > 0
      updated = self.saved_changes

      EtheloApi::Interface.update_participant(self, self.influence) if updated[:influence] || self.influence != self.influence
    end
  end

  before_destroy do
    if cached_repo_id.present? && cached_repo_id.to_i > 0
      EtheloApi::Interface.delete_participant(self)
    end
  end

  def cached_influent
    create_participant!
    @influent ||= decision.cached_repo.load_influent_for(self)
    @influent || {}
  end

  def resync_influent
    create_participant!
    @influent = decision.cached_repo.resync_influent_for(self)
    @influent || {}
  end

  def clear_influent_cache
    decision.cached_repo.clear_influent_cache(self)
  end

end
