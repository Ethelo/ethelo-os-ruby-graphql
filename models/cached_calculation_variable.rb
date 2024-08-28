require 'composite_primary_keys'

class CachedCalculationVariable < CachedRecord
  include WithDecisionTime

  upsert_keys [:cached_calculation_id, :cached_variable_id]
  self.primary_keys = :cached_calculation_id, :cached_variable_id

  belongs_to :cached_decision
  belongs_to :decision
  belongs_to :cached_variable
  belongs_to :cached_calculation
  validates_presence_of(:cached_calculation, :cached_variable, :cached_decision, :decision)

  # extract detail values from calculation section,will return an array of hash
  def self.attributes_from_graphql(graphql_hash, settings = {})
    attrs = super(graphql_hash)
    calculation_id = graphql_hash[:id]
    attrs.delete(:id)

    list = graphql_hash[:variables].each_with_object([]) do |variable, memo|
      extract = {
        cached_variable_id: variable[:id],
        cached_calculation_id: calculation_id,
      }
      memo << attrs.merge(extract)
    end

    list
  end

  def self.upsert_from_graphql(graphql_hash, settings = {})
    records = self.attributes_from_graphql(graphql_hash, settings)
    records.each {|attrs| self.upsert(attrs, validate: false)}
  end

end
