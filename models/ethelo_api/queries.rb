module EtheloApi
  class Queries

    LOAD_DECISION_STRUCTURE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query($decision_id: ID!) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          decision:summary{
            ...EtheloApi::Fragments::DECISION_SUMMARY_FRAGMENT
          }
          calculations{
            ...EtheloApi::Fragments::CALCULATION_FRAGMENT
          }
          constraints{
            ...EtheloApi::Fragments::CONSTRAINT_FRAGMENT
          }
          criterias{
            ...EtheloApi::Fragments::CRITERION_FRAGMENT
          }
          optionCategories{
            ...EtheloApi::Fragments::OPTION_CATEGORY_FRAGMENT
          }
          optionDetails{
            ...EtheloApi::Fragments::OPTION_DETAIL_FRAGMENT
          }
          optionFilters{
            ...EtheloApi::Fragments::OPTION_FILTER_FRAGMENT
          }
          options{
            ...EtheloApi::Fragments::OPTION_FRAGMENT
          }
          scenarioConfigs{
            ...EtheloApi::Fragments::SCENARIO_CONFIG_FRAGMENT
          }
          variables{
            ...EtheloApi::Fragments::VARIABLE_FRAGMENT
          }
        }
      }
    GRAPHQL

    LOAD_DECISION_ID = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query(
        $decision_id: ID!
      ) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          decision:summary{
            id
          }
        }
      }
    GRAPHQL

    LOAD_DECISION_EXPORT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query(
        $decision_id: ID!
      ) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          decision:summary{
            export
          }
        }
      }
    GRAPHQL

    LOAD_DECISION_JSON_DUMP = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query(
        $decision_id: ID!
        $scenario_config_id: ID!
        $participant_id: ID
        $use_cache: Boolean
      ) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          decision:summary{
            jsonDump(scenarioConfigId:$scenario_config_id,
                     participantId:$participant_id,
                     cached:$use_cache)
            {
              configJson
              decisionJson
              influentsJson
              weightsJson
              hash
            }
          }
        }
      }
    GRAPHQL

    LOAD_DECISION_VOTES_HISTOGRAM = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query($decision_id: ID!) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          decision:summary{
            votesHistogram { datetime count }
          }
        }
      }
    GRAPHQL

    LOAD_DECISION_PUBLISH_STATUS = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query(
        $decision_id: ID!
        $group_config_id: ID!
        $participant_config_id: ID!
       ) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          published:summary{
            decision:cachePresent
            groupConfig:configCachePresent(scenarioConfigId: $group_config_id)
            participantConfig:configCachePresent(scenarioConfigId: $participant_config_id)
          }
        }
      }
    GRAPHQL

    LOAD_DECISION_ERRORS = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query(
        $decision_id: ID!
      ) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          scenarioSets(status:"error") {
            id
            error
            insertedAt
            scenarioConfigId
          }
        }
      }
    GRAPHQL

    LOAD_SOLVE_DUMPS = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query(
        $decision_id: ID!
        $participant_id: ID
        $full_dump: Boolean!
        $scenario_set_id: ID
       ) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          scenarioSets(
           participantId: $participant_id  
           cachedDecision: true
           id: $scenario_set_id
          ) {
            id
            error
            status
            insertedAt
            published:cachedDecision
            updatedAt
            engineStart
            engineEnd
            solveDump @include(if: $full_dump){
              ...EtheloApi::Fragments::SOLVE_DUMP_FRAGMENT
             }
             dumpId:solveDump{
                id
             }
            scenarioConfigId
            scenarioCount: count(status: "success", global: false)
          }
        }
      }
    GRAPHQL


    LOAD_RANKED_SCENARIO = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query(
          $decision_id: ID!
          $participant_id: ID
          $scenario_config_id: ID
          $cached: Boolean
          $rank: Int
          $include_ranked: Boolean!
          $include_global: Boolean!
          $status: String
          $include_dump: Boolean!
          $count: Int
        ) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
      
          scenarioSets(
            participantId: $participant_id
            latest: true
            status: $status
            scenarioConfigId: $scenario_config_id
            cachedDecision: $cached
           ){
            id
            status
            error
            published:cachedDecision
            insertedAt
            updatedAt
            engineStart
            engineEnd
            scenarioConfigId

            participantId
            count(status: "success", global: false)

            solveDump @include(if: $include_dump){
             ...EtheloApi::Fragments::SOLVE_DUMP_FRAGMENT
            }
            dumpId:solveDump{
               id
            }

            summaryResults: scenarioStats @include(if: $include_global){
             ...EtheloApi::Fragments::SCENARIO_RESULTS_FRAGMENT
            }

            ranked_scenarios:scenarios(status: "success", global: false, rank: $rank, count: $count) @include(if: $include_ranked){
            ...EtheloApi::Fragments::SCENARIO_FRAGMENT
            }

            summary_scenarios:scenarios(global: true, rank: 0) @include(if: $include_global){
            ...EtheloApi::Fragments::SCENARIO_FRAGMENT
            }
          }
        }
      }
    GRAPHQL

    LOAD_PARTICIPANT_INFLUENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query($decision_id: ID!, $participant_id: ID!) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          participants(id: $participant_id) {
            id
            weighting

            binVotes {
              ...EtheloApi::Fragments::BIN_VOTE_FRAGMENT
            }

            optionCategoryRangeVotes {
              ...EtheloApi::Fragments::OPTION_CATEGORY_RANGE_VOTE_FRAGMENT
            }

            optionCategoryWeights {
              ...EtheloApi::Fragments::OPTION_CATEGORY_WEIGHT_FRAGMENT
            }

            criterionWeights:criteriaWeights {
              ...EtheloApi::Fragments::CRITERION_WEIGHT_FRAGMENT
            }
          }
        }
      }
    GRAPHQL

    LOAD_PARTICIPANT_LIST = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query($decision_id: ID!) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          participants {
            id
            weighting
          }
        }
      }
    GRAPHQL

    LOAD_ALL_INFLUENTS = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      query($decision_id: ID!) {
        queryResult: decision(
          decisionId: $decision_id
        )
        {
          meta{
            ...EtheloApi::Fragments::META_FRAGMENT
          }
          participants {
            id
            weighting

            binVotes {
              ...EtheloApi::Fragments::BIN_VOTE_FRAGMENT
            }

            optionCategoryRangeVotes {
              ...EtheloApi::Fragments::OPTION_CATEGORY_RANGE_VOTE_FRAGMENT
            }

            optionCategoryWeights {
              ...EtheloApi::Fragments::OPTION_CATEGORY_WEIGHT_FRAGMENT
            }

            criterionWeights:criteriaWeights {
              ...EtheloApi::Fragments::CRITERION_WEIGHT_FRAGMENT
            }
          }
        }
      }
    GRAPHQL
  end
end
