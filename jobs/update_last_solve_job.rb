class UpdateLastSolveJob < SolveDecisionBaseJob
  include Sidekiq::Worker
  sidekiq_options queue: :engine,
                  dead: false,
                  on_conflict: { server: :reject },
                  lock: :until_executed

  def perform(decision_id)
    decision = Decision.find(decision_id)

    begin
      decision.update_last_solved_at
    rescue
      #do nothing
    end
  end
end
