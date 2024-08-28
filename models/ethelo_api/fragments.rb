module EtheloApi
  class Fragments

    BIN_VOTE_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on BinVote {
        id
        participantId
        optionId
        criterionId: criteriaId
        bin
        updatedAt
      }
    GRAPHQL

    OPTION_CATEGORY_BIN_VOTE_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on OptionCategoryBinVote {
        id
        participantId
        optionCategoryId
        criterionId: criteriaId
        bin
        updatedAt
      }
      GRAPHQL

    OPTION_CATEGORY_RANGE_VOTE_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on OptionCategoryRangeVote {
        id
        participantId
        optionCategoryId
        highOptionId
        lowOptionId
        updatedAt
      }
    GRAPHQL

  CRITERION_FRAGMENT =EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Criteria {
        id
        title
        slug
        info
        deleted
        weighting
        sort
        applyParticipantWeights
        updatedAt
        insertedAt
      }
    GRAPHQL

    CRITERION_WEIGHT_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on CriteriaWeight {
        id
        participantId
        criterionId: criteriaId
        weighting
        updatedAt
      }
    GRAPHQL

    DECISION_SUMMARY_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on DecisionSummary {
        id
        title
        slug
        info
        copyable
        keywords
        internal
        language
        maxUsers
        updatedAt
        insertedAt
      }
    GRAPHQL

    MESSAGES_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on ValidationMessage{
        code
        field
        message
      }

    GRAPHQL

    META_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Meta{
        successful
        messages{
          ...EtheloApi::Fragments::MESSAGES_FRAGMENT
        }
        completedAt
      }
    GRAPHQL

    OPTION_CATEGORY_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on OptionCategory {
        id
        title
        resultsTitle
        slug
        info
        keywords
        deleted
        weighting
        xor
        quadratic
        scoringMode
        triangleBase
        applyParticipantWeights
        primaryDetailId
        votingStyle
        defaultLowOptionId
        defaultHighOptionId
        sort
        budgetPercent
        flatFee
        voteOnPercent
        updatedAt
        insertedAt
      }
    GRAPHQL

    OPTION_CATEGORY_WEIGHT_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on OptionCategoryWeight {
        id
        participantId
        optionCategoryId
        weighting
        updatedAt
      }
    GRAPHQL

    OPTION_DETAIL_FRAGMENT= EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on OptionDetail {
        id
        title
        slug
        format
        displayHint
        inputHint
        public
        sort
        updatedAt
        insertedAt
      }
    GRAPHQL

    OPTION_FILTER_FRAGMENT= EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on OptionFilter {
        id
        title
        slug
        matchValue
        matchMode
        updatedAt
        insertedAt
        cachedOptionCategoryId:optionCategoryId
        cachedOptionDetailId:optionDetailId
        options{
          id
        }  
        
      }
    GRAPHQL

    OPTION_DETAIL_VALUE_FRAGMENT= EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on OptionDetailValue {
        value
        optionDetail{
          id
        }
        option{
          id
        }        
     }
    GRAPHQL

    OPTION_FRAGMENT= EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Option {
        id
        title
        resultsTitle
        slug
        info
        enabled
        deleted
        sort
        updatedAt
        insertedAt
        optionCategory{
          id
        }
        detailValues{
          value
          optionDetail{
            id
          }
        }
      }
    GRAPHQL

    SOLVE_DUMP_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
    fragment on SolveDump {
      id
      scenarioSetId
      participantId
      decisionJson
      influentsJson
      weightsJson
      configJson
      responseJson
      error
      insertedAt
      updatedAt
    }
    GRAPHQL

    SCENARIO_CALCULATIONS_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on ScenarioDisplay {
        id
        name
        value
        calculationId
        constraintId
        isConstraint
        insertedAt
        updatedAt
      }
    GRAPHQL

    SCENARIO_RESULTS_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on ScenarioStats {
        scenarioId
        criterionId: criteriaId
        optionId
        optionCategoryId: issueId
        
        ethelo
        approval
        support
        dissonance
        histogram
        advancedStats
        totalVotes
        negativeVotes
        neutralVotes
        positiveVotes
        abstainVotes
        averageWeight

        seedsAssigned
        positiveSeedVotesSq
        positiveSeedVotesSum
        seedAllocation
        voteAllocation
        combinedAllocation
        finalAllocation
      }
    GRAPHQL

    SCENARIO_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Scenario {
        id
        status
        options {                     
          id
        }
        global
        minimize
        collectiveIdentity
        updatedAt
       
        calculatedValues: displays{
           ...EtheloApi::Fragments::SCENARIO_CALCULATIONS_FRAGMENT      
        }
        
        scenarioResults: stats{
          ...EtheloApi::Fragments::SCENARIO_RESULTS_FRAGMENT
        }
      }
    GRAPHQL

    SCENARIO_CONFIG_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on ScenarioConfig {
        id
        title
        slug
        bins
        collectiveIdentity
        enabled
        maxScenarios
        normalizeInfluents
        normalizeSatisfaction
        skipSolver
        supportOnly
        perOptionSatisfaction
        tippingPoint
        solveInterval
        ttl
        
        quadratic
        quadUserSeeds
        quadTotalAvailable
        quadCutoff
        quadMaxAllocation
        quadRoundTo
        quadSeedPercent
        quadVotePercent     
      }
    GRAPHQL

    PARTICIPANT_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Participant {
        id
        cachedRepoId: id
        weighting
      }
    GRAPHQL

    CALCULATION_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Calculation {
        id
        title
        personalResultsTitle
        slug
        expression
        displayHint
        public
        updatedAt
        insertedAt
        sort
        variables{
          id
        }  
      }
    GRAPHQL

    CONSTRAINT_FRAGMENT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Constraint {
        id
        title
        slug
        relaxable
        operator
        value
        betweenHigh
        betweenLow
        enabled
        updatedAt
        insertedAt
        variable{
          id
        }
        calculation{
          id
        }  
        optionFilter{
          id
        }    
      }
    GRAPHQL

    VARIABLE_FRAGMENT= EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      fragment on Variable {
        id
        title
        slug
        method
        updatedAt
        insertedAt
        cachedOptionFilterId:optionFilterId
        cachedOptionDetailId:optionDetailId
        calculations{
          id
        }  
        
      }
    GRAPHQL

  end
end
