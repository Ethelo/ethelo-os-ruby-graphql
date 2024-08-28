class CachedCalculation < CachedRecord

  belongs_to :decision
  belongs_to :cached_decision
  has_many :cached_calculation_variables
  has_many :cached_variables, through: :cached_calculation_variables, dependent: :nullify # remove association but not variable
  has_many :cached_constraints

  attribute :public, :boolean, default: true
  attribute :expression, :string
  attribute :display_hint, :string, default: '0.00'
  attribute :personal_results_title, :string, default: nil
  attribute :sort, :integer, default: 0

  validates :title, presence: true, no_html: true
  validates :slug, no_html: true

  ADMIN_FORMATS = {
    number_with_decimals: { key: :number_with_decimals, caption: "Number with Decimal (X.XX)", display_hint: '0.00' },
    dollars_and_cents: { key: :dollars_and_cents, caption: "Dollars and Cents ($X.XX)", display_hint: '$0.00' },
    percent_with_decimals: { key: :percent_with_decimals, caption: "Percent with Decimal (X.XX%)", display_hint: '0.00%' },
    number: { key: :number, caption: "Number", display_hint: '0' },
    dollars: { key: :dollars, caption: "Dollars ($X)", display_hint: '$0' },
    big_number: { key: :big_number, caption: "Big Number (X k)", display_hint: '0 k' },
    big_dollars: { key: :big_dollars, caption: "Big Dollars ($X k)", display_hint: '$0 k' },
    percent: { key: :percent, caption: "Percent (X%)", display_hint: '0%' },
  }

  validates :admin_format_key, inclusion: { in: ADMIN_FORMATS.keys }

  def self.format_value(admin_format_key, value)
    case admin_format_key
    when :percent
      (value.to_i * 100).to_s + "%"
    when :percent_with_decimals
      ("%.2f" % (value.to_f * 100)) + "%"
    when :number
      value.to_i
    when :dollars
      "$#{value.to_i}"
    when :big_number
      value.to_i
    when :big_dollars
      "$#{value.to_i}"
    when :number_with_decimals
      "%.2f" % value.to_f
    when :dollars_and_cents
      "$#{ "%.2f" % value.to_f}"
    else
      value
    end
  end

  def constrained?
    cached_constraints.count > 0
  end

  def constraints
    cached_constraints.to_a.reduce({}) do |memo, constraint|
      memo[constraint.id] = constraint
      memo
    end
  end

  def admin_format_key=(admin_format_key)
    admin_format_key = admin_format_key.to_sym
    admin_format_config = ADMIN_FORMATS[admin_format_key] || ADMIN_FORMATS[:number_with_decimals]
    self.display_hint = admin_format_config[:display_hint]
    @admin_format_key = admin_format_config[:admin_format]
  end

  def admin_format_key
    @admin_format_key ||= self.class.admin_format_matching(self.display_hint)
  end

  def admin_format_caption
    ADMIN_FORMATS[admin_format_key][:caption]
  end

  def self.admin_format_matching(display_hint)
    formats = ADMIN_FORMATS.values

    nil_match = nil
    display_match = nil

    formats.each do |admin_format|
      nil_match = admin_format[:key] if admin_format[:display_hint].nil?
      display_match = admin_format[:key] if admin_format[:display_hint] == display_hint
    end

    display_match || nil_match || :number_with_decimals
  end

  # [Caption, value]
  def self.admin_format_for_select
    ADMIN_FORMATS.map { |k, v| [v[:caption], k] }.to_h
  end

  def self.for_select(decision)
    decision.cached_calculations.order(:title).pluck(:title, :id)
  end

  def split_expression
    return [] if self.expression.blank?
    self.expression.split(/([A-Z_0-9\.\{]*)/i)
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash)
    attrs[:display_hint] = nil if attrs[:display_hint].blank?
    attrs
  end

  def attributes_for_graphql
    base = super
    base[:display_hint] = '' if base[:display_hint].blank?
    base
  end

end
