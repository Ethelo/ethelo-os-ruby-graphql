class SolvePersonalDecisionJob < SolveDecisionBaseJob
  sidekiq_options queue: :engine, lock: :until_clean_rerun, on_conflict: :mark_dirty  
end
