class Decision < ApplicationRecord
  belongs_to :cached_decision, optional: true, :dependent => :destroy
  has_many :cached_calculations
  has_many :cached_constraints
  has_many :cached_criteria
  has_many :cached_options
  has_many :cached_option_categories
  has_many :cached_option_details
  has_many :cached_option_detail_values
  has_many :cached_option_filters
  has_many :cached_variables
  has_many :cached_scenario_configs

  has_many :decision_users, :dependent => :destroy
  def cached_repo
    @repo ||= EtheloApi::Repo.new(self.cached_decision.id, self.id)
  end

  def rebuild
    cached_repo.rebuild_decision if self.cached_decision
  end

  def resync!
    cached_repo.resync_decision! if self.cached_decision
  end

  def publish
    return false unless self.cached_decision
    Decision.transaction do
      cached_criteria.where(deleted: true).each { |criteria| criteria.do_not_sync = true; criteria.delete }
      cached_options.where(deleted: true).each { |option| option.do_not_sync = true; option.delete }
      cached_option_categories.where(deleted: true).each { |option_category| option_category.do_not_sync = true; option_category.delete }
      self.resync!
      self.reload
      success = cached_repo.publish_decision
      if success
        self.update_column(:last_published, Time.current)
        SolveConfig.create_for(self, nil, true).schedule_solve(true, true)
        SolveConfig.create_for(self, nil, false).schedule_solve(false, true)
      else
        raise ActiveRecord::Rollback
      end
      success
    end
  end


  # solves

  def participant_scenario_config
    cached_scenario_configs.where(slug: CachedScenarioConfig::PARTICIPANT_SLUG).first ||
      CachedScenarioConfig.create_config_for_participant(self)
  end

  def group_scenario_config
    cached_scenario_configs.where(slug: CachedScenarioConfig::GROUP_SLUG).first ||
      CachedScenarioConfig.create_config_for_group(self)
  end

  def force_group_solve
    SolveConfig.create_for(self, nil, true).solve_now(true)
  end

  def group_scenarios(count = 10, include_global = false, **query_vars)
    query_vars.merge!({ rank: 1, count: count, include_global: include_global })
    cached_repo.load_scenarios(SolveConfig.create_for(self, nil, true), **query_vars)
  end

  def group_scenario_at_rank(rank = 1, include_global = false)
    SolveConfig.create_for(self, nil, true).load_scenario_at_rank(rank, include_global: include_global)
  end

  def update_last_solved_at(new_time = nil)
    if new_time.nil?
      latest_scenario = group_scenario_at_rank(1, false)
      return unless latest_scenario.present?
      return unless latest_scenario[:meta][:status] == "success"
      new_time = DateTime.parse(latest_scenario[:meta][:updated_at])
    end
    return if new_time.nil?
    return if last_solved_at.present? && new_time < last_solved_at
    update_attribute(:last_solved_at, new_time)
  end

  def current_solve_error
    solves = cached_repo.load_solve_dumps[:data] || []
    grouped = solves.reject { |ss| ss[:error] == 'no votes' }
                .group_by { |ss| ss[:status].to_sym }
    return nil unless grouped[:error].present?
    latest_error = grouped[:error].max_by { |ss| ss[:updated_at] }
    return latest_error[:error] unless grouped[:success].present?
    latest_success = grouped[:success].max_by { |ss| ss[:updated_at] }
    return nil if latest_success[:updated_at] > latest_error[:updated_at]
    latest_error[:error]
  end

  def force_decision_user_solve(decision_user)
    SolveConfig.create_for(self, decision_user, true).solve_now(true)
  end

  def decision_user_scenario(decision_user, include_global = true)
    SolveConfig.create_for(self, decision_user, true).load_scenario_at_rank(1, include_global: include_global)
  end

  def create_cached_decision
    cached = CachedDecision.where(id: cached_decision_id).first unless cached_decision_id.blank?

    unless cached
      cached = CachedDecision.new({ slug: slug, title: title, info: info })
      cached.save
    end

    if cached.errors.count > 0
      cached.errors.each do |attribute, error|
        self.errors.add(attribute, error)
      end
      throw(:abort)
    else
      self.cached_decision = cached
      self.slug = cached.slug
      self
    end
  end

  def update_cached_decision
    cached_keys = [:slug, :title, :info]
    changes = self.changes.slice(*cached_keys)

    return if changes.empty? || cached_decision_id.blank?
    cached = CachedDecision.find_by(id: cached_decision_id)
    cached.do_not_sync = true

    updates = { slug: slug, title: title, info: info }
    cached.update_attributes(updates)

    if cached.errors.count > 0
      cached.errors.each do |attribute, error|
        self.errors.add(attribute, error)
      end
      throw(:abort)
    end
  end

  before_create do
    create_cached_decision
  end

  before_update do
    self.slug = self.slug&.downcase
    update_cached_decision
  end

  before_destroy do |decision|
    cached_repo.delete_decision
  end

end
