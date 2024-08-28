class CachedDecision < CachedRecord
  has_one :decision, required: false
  has_many :cached_calculations
  has_many :cached_constraints
  has_many :cached_criteria
  has_many :cached_options
  has_many :cached_option_categories
  has_many :cached_option_details
  has_many :cached_option_detail_values
  has_many :cached_option_filters
  has_many :cached_variables

  validates :title, presence: true, no_html: true
  validates :slug, no_html: true

  def save
    return false unless self.valid?
    if self.persisted?
      super
    else
      EtheloApi::Repo.create_decision(self)

      if self.errors.count > 0
        false
      else
        CachedDecision.upsert(self.as_json)
      end
    end
  end

  def attributes_for_graphql
    self.as_json.symbolize_keys
  end

end
