require 'composite_primary_keys'

class CachedOptionDetailValue < CachedRecord

  upsert_keys [:cached_option_id, :cached_option_detail_id]
  self.primary_keys = :cached_option_id, :cached_option_detail_id

  belongs_to :cached_decision
  belongs_to :decision
  belongs_to :cached_option_detail
  belongs_to :cached_option, inverse_of: :cached_option_detail_values
  validates_presence_of(:cached_option, :cached_option_detail, :cached_decision, :decision)

  def admin_format_key
    cached_option_detail&.admin_format_key
  end

  def self.build_missing_odvs_for_option(decision, option)

    decision = Decision.includes(cached_option_detail_values: [:cached_option_detail], cached_option_details: []).find(decision.id)

    odvs = decision.cached_option_detail_values.inject({}) do |list, odv|
      list["#{odv.cached_option_detail_id}-#{odv.cached_option_id}"] = odv if odv.cached_option_id == option.id
      list
    end

    missing = {}

    decision.cached_option_details.each do |option_detail|
      key = "#{option_detail.id}-#{option.id}"
      unless odvs[key].present?
        missing[key] = CachedOptionDetailValue.new do |odv|
          odv.decision = decision
          odv.cached_decision = decision.cached_decision
          odv.cached_option = option
          odv.cached_option_detail = option_detail
        end
      end
    end

    missing.values.sort_by { |odv| odv.cached_option_detail.title }
  end

  # extract detail values from option section,will return an array of hash
  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash, settings)
    option_id = graphql_hash[:id]

    list = graphql_hash[:detail_values].each_with_object([]) do |detail_value, memo|
      extract = {
        cached_option_detail_id: detail_value[:option_detail][:id],
        cached_option_id: option_id,
        value: detail_value[:value],
      }
      memo << attrs.merge(extract)
    end

    list
  end

  def self.upsert_from_graphql(graphql_hash, settings = {})
    records = self.attributes_from_graphql(graphql_hash, settings)
    records.each {|attrs| self.upsert(attrs, validate: false)}
  end


  def mutation_mode_name(mode)
    mode = 'UPSERT' if ['CREATE', 'UPDATE'].include? mode
    super(mode)
  end

end
