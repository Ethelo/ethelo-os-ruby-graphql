class CachedRecord < ApplicationRecord
  self.abstract_class = true

  attr_accessor :do_not_sync

  def attributes_for_graphql
    values = self.as_json.symbolize_keys
    if values[:cached_decision_id] != self.decision.cached_decision_id
      values[:cached_decision_id] = self.decision.cached_decision_id
    end
    values
  end

  def graphql_object_name()
    self.class.name.underscore.gsub('cached_', '').upcase
  end

  def mutation_mode_name(mode)
    mode.upcase
  end

  def self.attributes_from_graphql(graphql_hash, settings = {})
    field_list = self.attribute_names.map(&:to_sym)
    graphql_hash.slice(*field_list)
  end

  def self.upsert_from_graphql(graphql_hash, settings = {})
    attrs = self.attributes_from_graphql(graphql_hash, settings)
    self.upsert(attrs, validate: false)
  end

  before_validation do |record|
    if record.respond_to? :cached_decision
      record.cached_decision = record.decision&.cached_decision
    end
  end

  def save(options = {})
    return false unless self.valid?
    decision.cached_repo.save_to_api(self)
    if self.errors.count > 0
      false
    else
      if self.do_not_sync
        super
      else
        result = decision.cached_repo.resync_decision! # reload entire decision from graphql
        self.reload if self.id.present? && result != false # reload the instantiated object from updated database. Ensures created records show as persisted
      end
      self
    end
  end

  def destroy
    delete
  end

  def delete
    if persisted?
      result = decision.cached_repo.delete_from_api(self)
      decision.cached_repo.resync_decision! unless self.do_not_sync
    end
    @destroyed = true
    freeze
  end

end
