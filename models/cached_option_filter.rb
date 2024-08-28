class CachedOptionFilter < CachedRecord
  extend Enumerize

  belongs_to :decision
  belongs_to :cached_decision
  belongs_to :cached_option_category, optional: true
  belongs_to :cached_option_detail, optional: true
  has_many :cached_constraints
  has_many :cached_variables

  validates :title, presence: true, no_html: true
  validates :slug, no_html: true

  ALL_OPTIONS_MODES = %w(all_options)
  DETAIL_MATCH_MODES = %w(equals)

  CATEGORY_MATCH_MODES = %w(in_category  not_in_category)

  ALL_MATCH_MODES = DETAIL_MATCH_MODES + CATEGORY_MATCH_MODES + ALL_OPTIONS_MODES

  enumerize :match_mode, in: ALL_MATCH_MODES, default: :equals, i18n_scope: 'attributes.match_mode'
  validates :match_value, exclusion: {in: [nil]}, if: :option_detail_filter?
  validates :match_mode, inclusion: {in: DETAIL_MATCH_MODES}, if: :option_detail_filter?
  validates :match_mode, inclusion: {in: CATEGORY_MATCH_MODES}, if: :option_category_filter?

  def self.match_modes_for_select
    modes = self.enumerized_attributes[:match_mode].options
    modes.delete_if { |array| array[1] === 'all_options' } # special case mode cannot be selected
    modes
  end

  def option_detail_filter?
    self.cached_option_detail.present?
  end

  def option_category_filter?
    self.cached_option_category.present?
  end

  def constrained?
    return true if cached_constraints.count > 0
    return false if cached_variables.count < 1
    cached_variables.to_a.reduce(false) do |memo, variable|
      memo ? memo : variable.constrained?
    end
  end

  def constraints
    list = cached_constraints.to_a.reduce({}) do |memo, constraint|
      memo[constraint.id] = constraint
      memo
    end
    cached_variables.to_a.reduce(list) do |memo, variable|
      memo.merge(variable.constraints)
    end
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash, settings)
    attrs[:option_count] = graphql_hash[:options].count
    attrs[:match_mode] = attrs[:match_mode].to_s.downcase
    attrs.delete(:options)
    attrs
  end

  def attributes_for_graphql
    base = super
    base[:match_mode] = base[:match_mode].upcase
    base
  end

  def graphql_object_name()
    base = super
    if self.cached_option_detail.present?
      base.gsub('OPTION_FILTER', 'OPTION_DETAIL_FILTER')
    else
      base.gsub('OPTION_FILTER', 'OPTION_CATEGORY_FILTER')
    end
  end

  def self.for_select(decision)
    decision.cached_option_filters.order(:title).pluck(:title, :id)
  end

  def self.all_options_filter(decision)
    decision.cached_option_filters.where(match_mode: ALL_OPTIONS_MODES).first
  end

end
