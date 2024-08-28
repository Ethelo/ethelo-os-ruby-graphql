class CachedVariable < CachedRecord
  extend Enumerize

  belongs_to :decision
  belongs_to :cached_decision
  belongs_to :cached_option_filter, optional: true
  belongs_to :cached_option_detail, optional: true
  has_many :cached_constraints
  has_many :cached_calculation_variables
  has_many :cached_calculations, through: :cached_calculation_variables, dependent: :nullify # remove association but not variable

  validates :title, presence: true, no_html: true
  validates :slug, no_html: true

  DETAIL_METHODS = %w(sum_selected mean_selected sum_all mean_all)

  FILTER_METHODS = %w(count_selected count_all)

  ALL_METHODS = DETAIL_METHODS + FILTER_METHODS

  enumerize :method, in: ALL_METHODS, i18n_scope: 'attributes.method'
  validates :method, inclusion: {in: DETAIL_METHODS}, if: :option_detail_variable?
  validates :method, inclusion: {in: FILTER_METHODS}, if: :option_filter_variable?

  def option_detail_variable?
    self.cached_option_detail.present?
  end

  def option_filter_variable?
    self.cached_option_filter.present?
  end

  def constrained?
    return true if cached_constraints.count > 0
    return false if cached_calculations.count < 1
    cached_calculations.to_a.reduce(false) do |memo, calculation|
      memo ? memo : calculation.constrained?
    end
  end

  def constraints
    list = cached_constraints.to_a.reduce({}) do |memo, constraint|
      memo[constraint.id] = constraint
      memo
    end
    cached_calculations.to_a.reduce(list) { |memo, calculation| memo.merge(calculation.constraints) }
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash, settings)
    attrs[:calculation_count] = graphql_hash[:calculations].count
    attrs[:method] = graphql_hash[:method].downcase
    attrs
  end

  def attributes_for_graphql
    base = super
    base[:method] = base[:method].upcase
    base
  end

  def graphql_object_name()
    base = super
    if self.cached_option_detail.present?
      base.gsub!('VARIABLE', 'DETAIL_VARIABLE')
    else
      base.gsub!('VARIABLE', 'FILTER_VARIABLE')
    end
  end

  def self.for_select(decision)
    decision.cached_variables.order(:slug).pluck(:slug, :id)
  end

  def self.for_expression(decision)
    decision.cached_variables.order(:slug).pluck(:slug)
  end

end
