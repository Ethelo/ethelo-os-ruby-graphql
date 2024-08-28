class CachedConstraint < CachedRecord
  extend Enumerize

  belongs_to :decision
  belongs_to :cached_decision
  belongs_to :cached_option_filter
  belongs_to :cached_calculation, optional: true
  belongs_to :cached_variable, optional: true

  attribute :enabled, :boolean, default: true
  attribute :relaxable, :boolean, default: false
  validates :title, presence: true, no_html: true
  validates :slug, no_html: true

  OPERATORS = %w(equal_to less_than_or_equal_to greater_than_or_equal_to between)

  enumerize :operator, in: OPERATORS, i18n_scope: 'attributes.operator'
  validates :operator, presence: true
  validates :between_high, presence: true, numericality: true, if: :between_constraint?
  validates :between_low, presence: true, numericality: true, if: :between_constraint?
  validates :value, presence: true, numericality: true, unless: :between_constraint?

  def between_constraint?
    self.operator.to_s.to_sym == :between
  end

  before_validation do |constraint|
    constraint.set_all_options_filter unless constraint.cached_option_filter.present?
  end

  def set_all_options_filter
    self.cached_option_filter = CachedOptionFilter.all_options_filter(self.decision)
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash)
    attrs[:cached_variable_id] = graphql_hash.dig(:variable, :id)
    attrs[:cached_calculation_id] = graphql_hash.dig(:calculation, :id)
    attrs[:cached_option_filter_id] = graphql_hash.dig(:option_filter, :id)
    attrs[:operator] = graphql_hash[:operator].downcase
    attrs
  end

  def attributes_for_graphql
    base = super
    base[:operator] = base[:operator].upcase if base[:operator].present?
    base[:value] = base[:value].to_f.round(5) if base[:value].present?
    base[:between_high] = base[:between_high].to_f.round(5) if base[:between_high].present?
    base[:between_low] = base[:between_low].to_f.round(5) if base[:between_low].present?
    base
  end

  def graphql_object_name()
    base = super
    if self.between_constraint?
      base.gsub!('CONSTRAINT', 'BETWEEN_CONSTRAINT')
    else
      base.gsub!('CONSTRAINT', 'SINGLE_BOUNDARY_CONSTRAINT')
    end
  end

end
