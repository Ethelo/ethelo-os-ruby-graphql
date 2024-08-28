class CachedScenarioConfig < CachedRecord

  belongs_to :decision
  belongs_to :cached_decision

  GROUP_SLUG = :group
  PARTICIPANT_SLUG = :participant

  validates :title, presence: true, no_html: true
  validates :slug, no_html: true

  attribute :bins, :integer, default: '5'
  validates :bins, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 9}

  attribute :solve_interval, :integer, default: 10*60*1000 # 10 minutes
  validates :solve_interval, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 60*60*24*7*1000 # one week
  }

  attribute :ttl, :integer, default: 60*60*24 # 1 day
  validates :ttl, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 60*60*24*7 # one week
  }

  attribute :support_only, :boolean, default: false
  attribute :per_option_satisfaction, :boolean, default: false
  attribute :normalize_satisfaction, :boolean, default: true
  attribute :normalize_influents, :boolean, default: false
  attribute :skip_solver, :boolean, default: true
  attribute :quadratic, :boolean, default: false

  attribute :quad_user_seeds, :integer, default: 125
  validates :quad_user_seeds, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :validate_quadratic_fields?

  attribute :quad_total_available, :integer, default: 580000
  validates :quad_total_available, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :validate_quadratic_fields?

  attribute :quad_cutoff, :integer, default: 7500
  validates :quad_cutoff, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :validate_quadratic_fields?

  attribute :quad_max_allocation, :integer, default: 50000
  validates :quad_max_allocation, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :validate_quadratic_fields?

  attribute :quad_round_to, :integer, default: 5000
  validates :quad_round_to, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :validate_quadratic_fields?

  attribute :quad_seed_percent, :float, default: 0.75
  validates :quad_seed_percent, presence: true, numericality: { less_than: 1, greater_than: 0 }, if: :validate_quadratic_fields?

  attribute :quad_vote_percent, :float, default: 0.25
  validates :quad_vote_percent, presence: true, numericality: { less_than: 1, greater_than: 0 }, if: :validate_quadratic_fields?

  def validate_quadratic_fields?
    self.quadratic
  end

  attribute :max_scenarios, :integer, default: 3
  validates :max_scenarios, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20}

  attribute :collective_identity, :float, default: 0.5
  validates :collective_identity, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1}

  attribute :tipping_point, :float, default: 0.33333
  validates :tipping_point, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1}

  attribute :enabled, :boolean, default: true

  def attributes_for_graphql
    base = super
    base[:collective_identity] = base[:collective_identity].to_f.round(5) if base[:collective_identity].present?
    base[:tipping_point] = base[:tipping_point].to_f.round(5) if base[:tipping_point].present?
    base[:quad_seed_percent] = base[:quad_seed_percent].to_f.round(5) if base[:quad_seed_percent].present?
    base[:quad_vote_percent] = base[:quad_vote_percent].to_f.round(5) if base[:quad_vote_percent].present?
    base
  end

  class << self

    def participant_config_attributes
      {
        max_scenarios: 1,
        normalize_satisfaction: false,
        normalize_influents: false,
        solve_interval: 0,
        ttl: 30*60 # 30 min
      }
    end

    def group_config_attributes
      {
      }
    end

    def base_attributes(decision, slug)
      {decision: decision, cached_decision: decision.cached_decision, slug: slug, title: slug}
    end

    def create_config_for_group(decision)
      attributes = base_attributes(decision, self::GROUP_SLUG)
      config = self.new(attributes)
      config.save
      config
    end

    def create_config_for_participant(decision)
      attributes = base_attributes(decision, self::PARTICIPANT_SLUG)
                     .merge(participant_config_attributes)
      config = self.new(attributes)
      config.save
      config
    end
  end

end
