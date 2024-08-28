class CachedCriterion < CachedRecord
  belongs_to :decision
  belongs_to :cached_decision

  attribute :bins, :integer, default: 5
  attribute :weighting, :integer, default: 50

  validates :title, presence: true, no_html: true
  validates :slug, no_html: true
  validates :weighting, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 9999}
  attribute :apply_participant_weights, :boolean, default: true
  attribute :sort, :integer, default: 0

  attribute :deleted, :boolean, default: false

  before_validation do
    self.weighting = 50 if self.weighting.nil?
  end

  def self.for_select(decision)
    decision.cached_criteria.order(:title).pluck(:title, :id)
  end

end
