class CachedOption < CachedRecord

  belongs_to :decision
  belongs_to :cached_option_category
  belongs_to :cached_decision

  has_many :cached_option_detail_values
  accepts_nested_attributes_for :cached_option_detail_values

  validates :title, presence: true, no_html: true
  validates :results_title, no_html: true
  validates :slug, no_html: true

  attribute :enabled, :boolean, default: true
  attribute :deleted, :boolean, default: false
  attribute :determinative, :boolean, default: false
  attribute :sort, :integer, default: 0


  def title_for_results
    (results_title || title).strip
  end

  def publishable?
    self.enabled && !self.deleted
  end

  def reportable?
    return false if self.deleted
    return false unless self.enabled
    slug != SettingsSidebars::AUTO_BALANCE_SLUG
  end

  before_validation do
    self.info = clean_html(self.info)
    self.determinative = !!self.determinative
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash)
    attrs[:cached_option_category_id] = graphql_hash[:option_category][:id]
    attrs
  end

  def fill_odvs
    CachedOptionDetailValue.build_missing_odvs_for_option(decision, self).each do |odv|
      new_odv = self.cached_option_detail_values.build
      new_odv.cached_option_detail = odv.cached_option_detail
      new_odv.decision = self.decision
      new_odv.cached_decision = self.cached_decision
    end
  end

  def self.for_select(decision)
    decision.cached_options.order(:title).pluck(:title, :id)
  end

  before_validation do
    odvs = self.cached_option_detail_values
    odvs.each do |odv|
      odv.cached_option = self
      odv.decision = self.decision
      odv.cached_decision = self.cached_decision
    end
  end

  def save(options={})
    prev_do_no_sync = self.do_not_sync
    self.do_not_sync = true
    success = super

    if success
      option_upsert = CachedOption.upsert(self.attributes_for_graphql)
      odvs = self.cached_option_detail_values

      odvs.each do |odv|
        unless odv.value.nil?
          odv.do_not_sync = true
          odv.cached_option_id = self.id
          odv_result = odv.save
          odv_result
        end
      end

      result = decision.cached_repo.resync_decision! unless prev_do_no_sync # reload entire decision from graphql
      self.reload if self.id.present? && result != false # reload the instantiated object from updated database. Ensures created records show as persisted
      self

    else
      success
    end
  end

end
