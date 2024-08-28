class CachedOptionCategory < CachedRecord
  belongs_to :decision
  belongs_to :cached_decision
  has_many :cached_options
  belongs_to :primary_detail, class_name: "CachedOptionDetail", optional: true
  belongs_to :default_high_option, class_name: "CachedOption", optional: true
  belongs_to :default_low_option, class_name: "CachedOption", optional: true

  DEFAULT_SLUG = 'uncategorized'

  attribute :weighting, :integer, default: 50
  validates :weighting, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 9999 }
  validates :title, presence: true, no_html: true
  validates :results_title, no_html: true
  validates :slug, no_html: true
  attribute :sort, :integer, default: 0

  attribute :keywords, :string
  validates :keywords, no_html: true

  attribute :deleted, :boolean, default: false
  attribute :xor, :boolean, default: false
  attribute :quadratic, :boolean, default: false
  attribute :apply_participant_weights, :boolean, default: true

  attribute :triangle_base, :integer, default: 3
  validates :triangle_base, numericality: { only_integer: true, greater_than: 0 }

  attribute :budget_percent, :float, default: nil
  validates :budget_percent, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  attribute :flat_fee, :float, default: nil
  validates :flat_fee, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  attribute :vote_on_percent, :boolean, default: true

  SCORING_MODES = %w(none triangle rectangle)
  attribute :scoring_mode, :string, default: :none
  validates :scoring_mode, inclusion: { in: SCORING_MODES }
  validates :primary_detail, presence: true, if: :detail_required?

  VOTING_STYLES = %w(one range)
  attribute :voting_style, :string, default: :one
  validates :voting_style, inclusion: { in: VOTING_STYLES }
  validates :default_high_option, presence: true, if: :high_option_required?
  attr_accessor :default_low_option_id_one, :default_low_option_id_range
  validates :default_low_option, presence: true, if: :low_option_required?
  validates :default_low_option_id_one, presence: true, if: :low_option_required?
  validates :default_low_option_id_range, presence: true, if: :low_option_required?

  def advanced_voting?
    ![:none, 'none'].include? self.scoring_mode
  end

  def title_for_results
    (results_title || title).strip
  end

  before_validation do
    self.deleted = false if is_default_category?
    self.weighting = 50 if self.weighting.nil?
    self.scoring_mode = self.scoring_mode.to_s.downcase
    self.voting_style = self.voting_style.to_s.downcase
    if self.voting_style == 'range'
      self.default_low_option_id = self.default_low_option_id_range
    else
      self.default_low_option_id = self.default_low_option_id_one
    end

    self.default_low_option_id = self.cached_option_ids[0] if self.default_low_option_id.nil?
    self.default_high_option_id = self.cached_option_ids[0] if self.default_high_option_id.nil?
    self.default_low_option_id_range = self.default_low_option_id
    self.default_low_option_id_one = self.default_low_option_id

    self.budget_percent = clean_number(self.budget_percent_before_type_cast)
    self.flat_fee = clean_number(self.flat_fee_before_type_cast)
  end

  def clean_number(value)
    return nil if value.nil?
    value.to_s.gsub(/[^0-9.]/, '')
  end

  after_find do
    self.default_low_option_id_range = self.default_low_option_id
    self.default_low_option_id_one = self.default_low_option_id
  end

  def detail_required?
    scoring_mode != 'none'
  end

  def high_option_required?
    detail_required? && voting_style == 'range' && cached_options.count > 0
  end

  def low_option_required?
    detail_required? && cached_options.count > 0
  end

  def self.default_category_for(decision)
    CachedOptionCategory.where(slug: CachedOptionCategory::DEFAULT_SLUG, decision_id: decision.id).first
  end

  def is_default_category?
    self.slug == self.class::DEFAULT_SLUG
  end

  def self.for_select(decision)
    decision.cached_option_categories.order(:title).pluck(:title, :id)
  end

  def self.sorted_options(options_with_odvs, primary_detail)
    sorted = options_with_odvs.to_a.sort_by { |option| [option.sort, option.title] }

    if primary_detail.blank?
      sorted
    else
      sorted.sort_by do |option|
        odv = option.cached_option_detail_values.to_a.find { |odv| odv.cached_option_detail_id == primary_detail.id }
        odv.present? ? odv.value.to_f : 0
      end
    end
  end

  def sorted_options
    @sorted_options ||= CachedOptionCategory.sorted_options(cached_options, primary_detail)
  end

  def options_with_detail_values
    @detail_options ||=
      begin
        if primary_detail.blank?
          {}
        else
          option_list = cached_options.includes(:cached_option_detail_values).order(:sort, :title).to_a

          option_list.map do |option|
            odv = option.cached_option_detail_values.find { |odv| odv.cached_option_detail_id == primary_detail.id }
            value = odv.present? ? odv.value.to_f : 0
            [option.id, CachedCalculation.format_value(odv.cached_option_detail.format, value)]
          end.to_h

        end

      end
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash, settings)
    attrs[:scoring_mode] = attrs[:scoring_mode].downcase
    attrs[:voting_style] = attrs[:voting_style].downcase

    unless settings[:with_options]
      attrs[:default_low_option_id] = nil
      attrs[:default_high_option_id] = nil
    end
    attrs
  end

  def attributes_for_graphql
    base = super
    base[:scoring_mode] = base[:scoring_mode].upcase
    base[:voting_style] = base[:voting_style].upcase
    base
  end


end
