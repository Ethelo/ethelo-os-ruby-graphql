class CachedOptionDetail < CachedRecord

  belongs_to :decision
  has_many :cached_option_detail_values
  has_many :cached_option_filters
  has_many :cached_variables
  has_many :cached_option_categories, foreign_key: :primary_detail_id

  accepts_nested_attributes_for :cached_option_detail_values

  attribute :public, :boolean, default: true
  attribute :format, :string, default: :string
  attribute :sort, :integer, default: 0

  FORMATS = %w(string integer float boolean) #datetime
  ADMIN_FORMATS = {
    string: {key: :string, caption: "Text", format: :string, input_hint: nil, display_hint: nil},
    big_number: {key: :big_number, caption: "Big Number (X k)", format: :integer, input_hint: nil, display_hint: '0 k'},
    number: {key: :number, caption: "Number", format: :integer, input_hint: nil, display_hint: nil},
    percent: {key: :percent, caption: "Percent (X%)", format: :integer, input_hint: '%', display_hint: '$0'},
    number_with_decimals: {key: :number_with_decimals, caption: "Number with Decimal (X.XX)", format: :float, input_hint: nil, display_hint: nil},
    dollars_and_cents: {key: :dollars_and_cents, caption: "Dollars and Cents ($X.XX)", format: :float, input_hint: '$', display_hint: '$0.00'},
    big_dollars: {key: :big_dollars, caption: "Big Dollars ($X k)", format: :integer, input_hint: '$', display_hint: '$0 k'},
    dollars: {key: :dollars, caption: "Dollars ($X)", format: :integer, input_hint: '$', display_hint: '$0'},
    percent_with_decimals: {key: :percent_with_decimals, caption: "Percent with Decimal (X.XX%)", format: :float, input_hint: '%', display_hint: '0%'},
    yes_no: {key: :yes_no, caption: "Yes/No", format: :boolean, input_hint: nil, display_hint: nil},
  }

  validates :title, presence: true, no_html: true
  validates :slug, no_html: true
  validates :format, inclusion: {in: FORMATS}
  validates :admin_format_key, inclusion: {in: ADMIN_FORMATS.keys}

  def admin_format_key=(admin_format_key)
    admin_format_key = admin_format_key.to_sym
    admin_format_config = ADMIN_FORMATS[admin_format_key] || ADMIN_FORMATS[:string]
    self.format = admin_format_config[:format]
    self.input_hint = admin_format_config[:input_hint]
    self.display_hint = admin_format_config[:display_hint]
    @admin_format_key = admin_format_config[:admin_format]
  end

  def admin_format_key
    @admin_format_key ||= CachedOptionDetail.admin_format_matching(self.format, self.input_hint, self.display_hint)
  end

  def admin_format_caption
    ADMIN_FORMATS[admin_format_key][:caption]
  end

  def self.admin_format_matching(format, input_hint, display_hint)
    matching_format = ADMIN_FORMATS.values.keep_if { |admin_format| admin_format[:format].to_s == format.to_s.downcase }

    nil_match = nil
    both_match = nil
    input_match = nil

    matching_format.each do |admin_format|
      nil_match = admin_format[:key] if admin_format[:input_hint].nil? && admin_format[:display_hint].nil?
      both_match = admin_format[:key] if admin_format[:input_hint] == input_hint && admin_format[:display_hint] == display_hint
      input_match =  admin_format[:key] if admin_format[:input_hint] == input_hint && display_hint.nil?
    end

    both_match || input_match || nil_match || :string
  end

  def constrained?
    return false unless self.cached_variables || self.cached_option_filters

    constrained = cached_option_filters.to_a.reduce(false) do |memo, option_filter|
      memo ? memo : option_filter.constrained?
    end

    return true if constrained

    cached_variables.to_a.reduce(false) do |memo, variable|
      memo ? memo : variable.constrained?
    end
  end

  def constraints
    list = {}
    list = cached_variables.to_a.reduce(list) { |memo, variable| memo.merge(variable.constraints) }
    cached_option_filters.to_a.reduce(list) { |memo, option_filter| memo.merge(option_filter.constraints) }
  end

  # [Caption, value]
  def self.admin_format_for_select
    ADMIN_FORMATS.map { |k, v| [v[:caption], k] }.to_h
  end

  def self.for_select(decision)
    decision.cached_option_details.order(:title).pluck(:title, :id)
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash)
    attrs[:format] = attrs[:format].downcase
    attrs[:input_hint] = nil if attrs[:input_hint].blank?
    attrs[:display_hint] = nil if attrs[:display_hint].blank?
    attrs
  end

  def attributes_for_graphql
    base = super
    base[:format] = base[:format].upcase
    base[:input_hint] = '' if base[:input_hint].blank?
    base[:display_hint] = '' if base[:display_hint].blank?
    base
  end
end
