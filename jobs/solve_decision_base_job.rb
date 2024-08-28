class SolveDecisionBaseJob
  include Sidekiq::Worker

  def invalid_params(decision_user, decision_user_id, decision)
    return false unless decision.present? # skip if decision deleted
    return false unless decision_user_id.present? #always solve group
    return true unless decision_user.present?
    return true unless decision_user.cached_repo_id.present?
    return true unless decision_user.cached_repo_id > 0
    false
  end

  def perform(decision_id, decision_user_id = nil, published=true, force=false, save_dump=false)
    decision = Decision.find_by(id: decision_id)
    begin
      decision_user = decision_user_id.present? ? DecisionUser.find_by(id: decision_user_id) : nil

      if invalid_params(decision_user, decision_user_id, decision)
        return
      end

      logger.debug("solving #{decision.slug} (#{decision_user_id}) with #{published ? "published" : "preview"} ")
      config = SolveConfig.create_for(decision, decision_user, published)
      decision.cached_repo.solve_decision(config, force, save_dump)
    end
  end
end
