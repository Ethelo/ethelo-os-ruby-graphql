module EtheloApi
  class Mutations

    class << self

      def field_list_for(mode, object)
        name = "#{self.name}::#{object.mutation_mode_name(mode)}_#{object.graphql_object_name}_FIELDS"
        list = name.safe_constantize
        return ['id', 'decision_id'] if mode == 'DELETE' && !list
        list || []
      end

      def query_for(mode, object)
        name = "#{self.name}::#{object.mutation_mode_name(mode)}_#{object.graphql_object_name}"
        name.constantize
      end

    end

    CREATE_DECISION_FIELDS = %w(title slug info max_users language copyable keywords internal)
    CREATE_DECISION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $title: String!
        $slug: String
        $info: String
        $keywords: [String]
        $language: String
        $max_users: Int
        $copyable: Boolean
        $internal: Boolean
      ) {
        createDecision(
          input: {
            title: $title
            slug: $slug
            info: $info
            keywords: $keywords
            language: $language
            copyable: $copyable
            internal: $internal
            maxUsers: $max_users
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::DECISION_SUMMARY_FRAGMENT
          }
        }
      }
    GRAPHQL

    IMPORT_DECISION_FIELDS = %w(export title slug info)
    IMPORT_DECISION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $export: String!
        $title: String
        $slug: String
        $info: String
      ) {
        importDecision(
          input: {
            export: $export
            title: $title
            slug: $slug
            info: $info
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::DECISION_SUMMARY_FRAGMENT
          }
        }
      }
    GRAPHQL

    CACHE_DECISION_FIELDS = %w(decision_id)
    CACHE_DECISION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
      ) {
        cacheDecision(
          input: {
            id: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_DECISION_FIELDS = %w(id title slug info language max_users keywords copyable internal)
    UPDATE_DECISION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $id: ID!
        $title: String!
        $slug: String
        $info: String
        $keywords: [String]
        $language: String
        $max_users: Int
        $copyable: Boolean
        $internal: Boolean
      ) {
        updateDecision(
          input: {
            id: $id
            title: $title
            slug: $slug
            info: $info
            keywords: $keywords
            language: $language
            copyable: $copyable
            internal: $internal
            maxUsers: $max_users
           }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::DECISION_SUMMARY_FRAGMENT
          }
        }
      }
    GRAPHQL

    COPY_DECISION_FIELDS = %w(id title slug info)
    COPY_DECISION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $id: ID!
        $title: String
        $slug: String
        $info: String
      ) {
        copyDecision(
          input: {
            id: $id
            title: $title
            slug: $slug
            info: $info
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::DECISION_SUMMARY_FRAGMENT
          }
        }
      }
    GRAPHQL

    SOLVE_DECISION_FIELDS = %w(decision_id participant_id scenario_config_id use_cache, force, save_dump)
    SOLVE_DECISION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $participant_id: ID
        $scenario_config_id: ID!
        $use_cache: Boolean
        $force: Boolean
        $save_dump: Boolean
      ) {
        solveDecision(
          input: {
            decisionId: $decision_id
            participantId: $participant_id
            scenarioConfigId: $scenario_config_id
            cached: $use_cache,
            force: $force
            saveDump: $save_dump
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            id
            status
          }
        }
      }
    GRAPHQL

    DELETE_DECISION_FIELDS = %w(id)
    DELETE_DECISION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $id: ID!
      )
      {
        deleteDecision(
          input: {
            id: $id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_CRITERION_FIELDS = %w(decision_id title slug info weighting apply_participant_weights deleted sort)
    CREATE_CRITERION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $info: String
        $weighting: Int
        $sort: Int
        $apply_participant_weights: Boolean
        $deleted: Boolean
      ) {
        createCriteria(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            info: $info
            weighting: $weighting
            sort: $sort
            applyParticipantWeights: $apply_participant_weights
            deleted: $deleted
            supportOnly: true
            bins: 5
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CRITERION_FRAGMENT
          }
        }
      }
    GRAPHQL

    # SupportOnly and Bins are hard coded until per option-criteria feature is built.
    UPDATE_CRITERION_FIELDS = CREATE_CRITERION_FIELDS + ['id']
    UPDATE_CRITERION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $slug: String
        $info: String
        $weighting: Int     
        $sort: Int
        $apply_participant_weights: Boolean
        $deleted: Boolean
      ) {
        updateCriteria(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            info: $info
            deleted: $deleted
            weighting: $weighting
            sort: $sort
            supportOnly: false
            applyParticipantWeights: $apply_participant_weights
            bins: 5
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CRITERION_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_CRITERION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteCriteria(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_OPTION_FIELDS = %w(decision_id title results_title slug option_category_id info enabled deleted sort determinative)
    CREATE_OPTION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $results_title: String
        $slug: String
        $option_category_id: ID
        $info: String
        $enabled: Boolean!
        $deleted: Boolean
        $determinative: Boolean
        $sort: Int
     ) {
        createOption(
          input: {
            decisionId: $decision_id
            title: $title
            resultsTitle: $results_title
            slug: $slug
            optionCategoryId: $option_category_id
            info: $info
            enabled: $enabled
            deleted: $deleted
            sort: $sort
            determinative: $determinative
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_OPTION_FIELDS = CREATE_OPTION_FIELDS + ['id']
    UPDATE_OPTION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $results_title: String
        $slug: String
        $option_category_id: ID
        $info: String
        $enabled: Boolean!
        $deleted: Boolean
        $sort: Int
        $determinative: Boolean
      ) {
        updateOption(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            resultsTitle: $results_title
            slug: $slug
            optionCategoryId: $option_category_id
            info: $info
            enabled: $enabled
            deleted: $deleted
            sort: $sort
            determinative: $determinative
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteOption(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_OPTION_CATEGORY_FIELDS = %w(
      decision_id id title results_title slug info keywords weighting deleted
      xor quadratic scoring_mode triangle_base apply_participant_weights
      budget_percent flat_fee vote_on_percent primary_detail_id
      voting_style default_high_option_id default_low_option_id sort
     )
    CREATE_OPTION_CATEGORY = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $results_title: String
        $slug: String
        $info: String
        $keywords: String
        $weighting: Int
        $deleted: Boolean
        $xor: Boolean
        $quadratic: Boolean
        $scoring_mode: ScoringMode!
        $triangle_base: Int
        $budget_percent: Float
        $flat_fee: Float
        $vote_on_percent: Boolean
        $apply_participant_weights: Boolean
        $primary_detail_id: ID
        $voting_style: VotingStyle!
        $default_low_option_id: ID
        $default_high_option_id: ID
        $sort: Int  
      ) {
        createOptionCategory(
          input: {
            decisionId: $decision_id
            title: $title
            resultsTitle: $results_title
            slug: $slug
            info: $info
            keywords: $keywords
            weighting: $weighting
            deleted: $deleted
            xor: $xor
            quadratic: $quadratic
            scoringMode: $scoring_mode
            triangleBase: $triangle_base
            applyParticipantWeights: $apply_participant_weights
            primaryDetailId: $primary_detail_id
            votingStyle: $voting_style
            defaultHighOptionId: $default_high_option_id
            defaultLowOptionId: $default_low_option_id
            sort: $sort
            budgetPercent: $budget_percent
            flatFee: $flat_fee
            voteOnPercent: $vote_on_percent
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_CATEGORY_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_OPTION_CATEGORY_FIELDS = CREATE_OPTION_CATEGORY_FIELDS + ['id']
    UPDATE_OPTION_CATEGORY = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $weighting: Int
        $title: String!
        $results_title: String
        $slug: String
        $info: String
        $keywords: String
        $deleted: Boolean
        $xor: Boolean
        $quadratic: Boolean
        $scoring_mode: ScoringMode!
        $triangle_base: Int
        $apply_participant_weights: Boolean
        $primary_detail_id: ID
        $voting_style: VotingStyle!
        $default_low_option_id: ID
        $default_high_option_id: ID
        $sort: Int
        $budget_percent: Float
        $flat_fee: Float
        $vote_on_percent: Boolean
      ) {
        updateOptionCategory(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            resultsTitle: $results_title
            slug: $slug
            weighting: $weighting
            info: $info
            keywords: $keywords
            deleted: $deleted
            xor: $xor
            quadratic: $quadratic
            scoringMode: $scoring_mode
            triangleBase: $triangle_base
            applyParticipantWeights: $apply_participant_weights
            primaryDetailId: $primary_detail_id           
            votingStyle: $voting_style
            defaultHighOptionId: $default_high_option_id
            defaultLowOptionId: $default_low_option_id
            sort: $sort
            budgetPercent: $budget_percent
            flatFee: $flat_fee
            voteOnPercent: $vote_on_percent
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_CATEGORY_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION_CATEGORY = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteOptionCategory(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_OPTION_DETAIL_FIELDS = %w(decision_id title slug format display_hint input_hint public sort)
    CREATE_OPTION_DETAIL = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $format: DetailFormat!
        $title: String!
        $slug: String
        $display_hint: String
        $input_hint: String
        $public: Boolean
        $sort: Int
      ) {
        createOptionDetail(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            format: $format
            displayHint: $display_hint
            inputHint: $input_hint
            public: $public
            sort: $sort
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_DETAIL_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_OPTION_DETAIL_FIELDS = CREATE_OPTION_DETAIL_FIELDS + ['id']
    UPDATE_OPTION_DETAIL = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $format: DetailFormat!
        $title: String!
        $slug: String
        $display_hint: String
        $input_hint: String
        $public: Boolean
        $sort: Int
      ) {
        updateOptionDetail(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            format: $format
            displayHint: $display_hint
            inputHint: $input_hint
            public: $public
            sort: $sort
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_DETAIL_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION_DETAIL = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteOptionDetail(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPSERT_OPTION_DETAIL_VALUE_FIELDS = %w(decision_id option_id option_detail_id value)
    UPSERT_OPTION_DETAIL_VALUE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $option_detail_id: ID!
        $option_id: ID!
        $value: String!
      ) {
        updateOptionDetailValue(
          input: {
            decisionId: $decision_id
            optionDetailId: $option_detail_id
            optionId: $option_id
            value: $value
           }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_DETAIL_VALUE_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION_DETAIL_VALUE_FIELDS = %w(decision_id option_id option_detail_id)
    DELETE_OPTION_DETAIL_VALUE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

   mutation(
    $decision_id: ID!
    $option_detail_id: ID!
    $option_id: ID!
   )
    {
      deleteOptionDetailValue(
        input: {
          optionDetailId: $option_detail_id
          optionId: $option_id
          decisionId: $decision_id
        }
      )
      {
        successful
        messages{
          ...EtheloApi::Fragments::MESSAGES_FRAGMENT
        }
      }
    }
    GRAPHQL

    CREATE_OPTION_CATEGORY_FILTER_FIELDS = %w(decision_id title slug option_category_id match_mode)
    CREATE_OPTION_CATEGORY_FILTER = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $option_category_id: ID!
        $match_mode: CategoryFilterMatchModes!
      ) {
        createOptionCategoryFilter(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionCategoryId: $option_category_id
            matchMode: $match_mode
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_FILTER_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_OPTION_CATEGORY_FILTER_FIELDS = CREATE_OPTION_CATEGORY_FILTER_FIELDS + ['id']
    UPDATE_OPTION_CATEGORY_FILTER = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $slug: String
        $option_category_id: ID!
        $match_mode: CategoryFilterMatchModes!
      ) {
        updateOptionCategoryFilter(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionCategoryId: $option_category_id
            matchMode: $match_mode
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_FILTER_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION_CATEGORY_FILTER = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteOptionFilter(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_OPTION_DETAIL_FILTER_FIELDS = %w(decision_id title slug option_detail_id match_mode match_value)
    CREATE_OPTION_DETAIL_FILTER = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $option_detail_id: ID!
        $match_mode: DetailFilterMatchModes!
        $match_value: String!
      ) {
        createOptionDetailFilter(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionDetailId: $option_detail_id
            matchMode: $match_mode
            matchValue: $match_value
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_FILTER_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_OPTION_DETAIL_FILTER_FIELDS = CREATE_OPTION_DETAIL_FILTER_FIELDS + ['id']
    UPDATE_OPTION_DETAIL_FILTER = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $slug: String
        $option_detail_id: ID!
        $match_mode: DetailFilterMatchModes!
        $match_value: String!
      ) {
        updateOptionDetailFilter(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionDetailId: $option_detail_id
            matchMode: $match_mode
            matchValue: $match_value
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_FILTER_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION_DETAIL_FILTER = DELETE_OPTION_CATEGORY_FILTER

    CREATE_DETAIL_VARIABLE_FIELDS = %w(decision_id title slug option_detail_id method)
    CREATE_DETAIL_VARIABLE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $option_detail_id: ID!
        $method: DetailVariableMethods!
      ) {
        createDetailVariable(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionDetailId: $option_detail_id
            method: $method
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::VARIABLE_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_DETAIL_VARIABLE_FIELDS = CREATE_DETAIL_VARIABLE_FIELDS + ['id']
    UPDATE_DETAIL_VARIABLE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $slug: String
        $option_detail_id: ID!
        $method: DetailVariableMethods!
      ) {
        updateDetailVariable(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionDetailId: $option_detail_id
            method: $method
           }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::VARIABLE_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_DETAIL_VARIABLE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteVariable(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_FILTER_VARIABLE_FIELDS = %w(decision_id title slug option_filter_id method)
    CREATE_FILTER_VARIABLE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $option_filter_id: ID!
        $method: FilterVariableMethods!
      ) {
        createFilterVariable(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionFilterId: $option_filter_id
            method: $method
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::VARIABLE_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_FILTER_VARIABLE_FIELDS = CREATE_FILTER_VARIABLE_FIELDS + ['id']
    UPDATE_FILTER_VARIABLE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $slug: String
        $option_filter_id: ID!
        $method: FilterVariableMethods!
      ) {
        updateFilterVariable(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            optionFilterId: $option_filter_id
            method: $method
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::VARIABLE_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_FILTER_VARIABLE = DELETE_DETAIL_VARIABLE

    CREATE_CALCULATION_FIELDS = %w(decision_id title personal_results_title slug expression display_hint public sort)
    CREATE_CALCULATION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $expression: String!
        $display_hint: String
        $public: Boolean
        $sort: Int
        $personal_results_title: String
      ) {
        createCalculation(
          input: {
            decisionId: $decision_id
            title: $title
            personalResultsTitle: $personal_results_title
            slug: $slug
            expression: $expression
            displayHint: $display_hint
            public: $public
            sort: $sort
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CALCULATION_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_CALCULATION_FIELDS = CREATE_CALCULATION_FIELDS + ['id']
    UPDATE_CALCULATION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $expression: String!
        $title: String!
        $personal_results_title: String
        $slug: String
        $display_hint: String
        $public: Boolean
        $sort: Int
      ) {
        updateCalculation(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            personalResultsTitle: $personal_results_title
            slug: $slug
            expression: $expression
            displayHint: $display_hint
            public: $public
            sort: $sort
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CALCULATION_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_CALCULATION = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteCalculation(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_SINGLE_BOUNDARY_CONSTRAINT_FIELDS = %w(
      decision_id title slug enabled relaxable
      calculation_id variable_id option_filter_id
      operator value
      )

    CREATE_SINGLE_BOUNDARY_CONSTRAINT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $enabled: Boolean
        $option_filter_id: ID!
        $calculation_id: ID
        $variable_id: ID
        $value: Float!
        $relaxable: Boolean
        $operator: SingleBoundaryConstraintOperators!
      ) {
        createSingleBoundaryConstraint(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            enabled: $enabled
            optionFilterId: $option_filter_id
            variableId: $variable_id
            value: $value
            calculationId: $calculation_id
            operator: $operator
            relaxable: $relaxable
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CONSTRAINT_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_SINGLE_BOUNDARY_CONSTRAINT_FIELDS = CREATE_SINGLE_BOUNDARY_CONSTRAINT_FIELDS + ['id']
    UPDATE_SINGLE_BOUNDARY_CONSTRAINT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $slug: String
        $enabled: Boolean
        $option_filter_id: ID!
        $calculation_id: ID
        $variable_id: ID
        $value: Float!
        $relaxable: Boolean
        $operator: SingleBoundaryConstraintOperators!
      ) {
        updateSingleBoundaryConstraint(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            enabled: $enabled
            optionFilterId: $option_filter_id
            variableId: $variable_id
            value: $value
            relaxable: $relaxable
            calculationId: $calculation_id
            operator: $operator
           }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CONSTRAINT_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_SINGLE_BOUNDARY_CONSTRAINT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteConstraint(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_BETWEEN_CONSTRAINT_FIELDS = %w(
      decision_id title slug enabled
      calculation_id variable_id option_filter_id
      between_low between_high
    )

    CREATE_BETWEEN_CONSTRAINT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $enabled: Boolean
        $relaxable: Boolean
        $option_filter_id: ID!
        $calculation_id: ID
        $variable_id: ID
        $between_low: Float!
        $between_high: Float!
      ) {
        createBetweenConstraint(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            enabled: $enabled
            calculationId: $calculation_id
            optionFilterId: $option_filter_id
            variableId: $variable_id
            betweenLow: $between_low
            betweenHigh: $between_high
            relaxable: $relaxable
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CONSTRAINT_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_BETWEEN_CONSTRAINT_FIELDS = CREATE_BETWEEN_CONSTRAINT_FIELDS + ['id']
    UPDATE_BETWEEN_CONSTRAINT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $id: ID!
        $decision_id: ID!
        $title: String!
        $slug: String
        $enabled: Boolean
        $relaxable: Boolean
        $option_filter_id: ID!
        $calculation_id: ID
        $variable_id: ID
        $between_low: Float!
        $between_high: Float!
      ) {
        updateBetweenConstraint(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            enabled: $enabled
            calculationId: $calculation_id
            optionFilterId: $option_filter_id
            variableId: $variable_id
            betweenLow: $between_low
            betweenHigh: $between_high
            relaxable: $relaxable
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CONSTRAINT_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_BETWEEN_CONSTRAINT = DELETE_SINGLE_BOUNDARY_CONSTRAINT

    CREATE_SCENARIO_CONFIG_FIELDS = %w(
      decision_id title slug
      bins collective_identity enabled max_scenarios normalize_influents normalize_satisfaction
      skip_solver quadratic support_only per_option_satisfaction tipping_point solve_interval ttl
      quad_cutoff quad_max_allocation quad_round_to quad_total_available quad_user_seeds
      quad_vote_percent quad_seed_percent
    )
    CREATE_SCENARIO_CONFIG = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $title: String!
        $slug: String
        $bins: Int
        $collective_identity: Float!
        $enabled: Boolean!
        $max_scenarios: Int
        $normalize_influents: Boolean
        $normalize_satisfaction: Boolean
        $skip_solver: Boolean!
        $support_only: Boolean!
        $per_option_satisfaction: Boolean!
        $tipping_point: Float!
        $solve_interval: Int
        $ttl: Int
        $quadratic: Boolean!
        $quad_cutoff: Int  
        $quad_max_allocation: Int 
        $quad_round_to: Int
        $quad_seed_percent: Float 
        $quad_total_available: Int 
        $quad_user_seeds: Int
        $quad_vote_percent: Float
      ) {
        createScenarioConfig(
          input: {
            decisionId: $decision_id
            title: $title
            slug: $slug
            bins: $bins
            collectiveIdentity: $collective_identity
            enabled: $enabled
            maxScenarios: $max_scenarios
            normalizeInfluents: $normalize_influents
            normalizeSatisfaction: $normalize_satisfaction
            skipSolver: $skip_solver
            supportOnly: $support_only
            perOptionSatisfaction: $per_option_satisfaction
            tippingPoint: $tipping_point
            solveInterval: $solve_interval
            ttl: $ttl
            quadratic: $quadratic
            quadCutoff: $quad_cutoff
            quadMaxAllocation: $quad_max_allocation
            quadRoundTo: $quad_round_to
            quadTotalAvailable: $quad_total_available
            quadUserSeeds: $quad_user_seeds
            quadVotePercent: $quad_vote_percent
            quadSeedPercent: $quad_seed_percent           
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::SCENARIO_CONFIG_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_SCENARIO_CONFIG_FIELDS = CREATE_SCENARIO_CONFIG_FIELDS + ['id']
    UPDATE_SCENARIO_CONFIG = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $id: ID!
        $title: String!
        $slug: String
        $bins: Int
        $collective_identity: Float!
        $enabled: Boolean!
        $max_scenarios: Int
        $normalize_influents: Boolean
        $normalize_satisfaction: Boolean
        $skip_solver: Boolean!
        $support_only: Boolean!
        $per_option_satisfaction: Boolean!
        $tipping_point: Float!
        $solve_interval: Int
        $ttl: Int
        $quadratic: Boolean!
        $quad_cutoff: Int  
        $quad_max_allocation: Int 
        $quad_round_to: Int
        $quad_seed_percent: Float 
        $quad_total_available: Int 
        $quad_user_seeds: Int
        $quad_vote_percent: Float
    ) {
        updateScenarioConfig(
          input: {
            id: $id
            decisionId: $decision_id
            title: $title
            slug: $slug
            bins: $bins
            collectiveIdentity: $collective_identity
            enabled: $enabled
            maxScenarios: $max_scenarios
            normalizeInfluents: $normalize_influents
            normalizeSatisfaction: $normalize_satisfaction
            skipSolver: $skip_solver
            supportOnly: $support_only
            perOptionSatisfaction: $per_option_satisfaction
            tippingPoint: $tipping_point
            solveInterval: $solve_interval
            ttl: $ttl
            quadratic: $quadratic
            quadCutoff: $quad_cutoff
            quadMaxAllocation: $quad_max_allocation 
            quadRoundTo: $quad_round_to
            quadTotalAvailable: $quad_total_available
            quadUserSeeds: $quad_user_seeds
            quadVotePercent: $quad_vote_percent
            quadSeedPercent: $quad_seed_percent        
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::SCENARIO_CONFIG_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_SCENARIO_CONFIG = EtheloApi::Runner.prepare_query <<-'GRAPHQL'

      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteScenarioConfig(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CACHE_SCENARIO_CONFIG_FIELDS = %w(decision_id id)
    CACHE_SCENARIO_CONFIG = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
       $decision_id: ID!
        $id: ID!
      ) {
        cacheScenarioConfig(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    CREATE_PARTICIPANT_FIELDS = %w(decision_id weighting)
    CREATE_PARTICIPANT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $weighting: Float
      ) {
        createParticipant(
          input: {
            decisionId: $decision_id
            weighting: $weighting
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::PARTICIPANT_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPDATE_PARTICIPANT_FIELDS = CREATE_PARTICIPANT_FIELDS + ['id']
    UPDATE_PARTICIPANT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $id: ID!
        $decision_id: ID!
        $weighting: Float
      ) {
        updateParticipant(
          input: {
            id: $id
            decisionId: $decision_id
            weighting: $weighting
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::PARTICIPANT_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_PARTICIPANT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteParticipant(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPSERT_BIN_VOTE_FIELDS = %w(decision_id participant_id option_id delete criterion_id bin)
    UPSERT_BIN_VOTE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $participant_id: ID!
        $option_id: ID!
        $criterion_id: ID!
        $bin: Int!
        $delete: Boolean
      ) {
        upsertBinVote(
          input: {
            decisionId: $decision_id
            participantId: $participant_id
            optionId: $option_id
            criteriaId: $criterion_id
            bin: $bin
            delete: $delete
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::BIN_VOTE_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_BIN_VOTE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteBinVote(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPSERT_OPTION_CATEGORY_BIN_VOTE_FIELDS = %w(decision_id participant_id option_category_id delete criterion_id bin)
    UPSERT_OPTION_CATEGORY_BIN_VOTE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
    mutation (
      $decision_id: ID!
      $participant_id: ID!
      $option_category_id: ID!
      $criterion_id: ID!
      $bin: Int!
      $delete: Boolean
    ) {
      upsertOptionCategoryBinVote(
        input: {
          decisionId: $decision_id
          participantId: $participant_id
          optionCategoryId: $option_category_id
          criteriaId: $criterion_id
          bin: $bin
          delete: $delete
        }
      )
      {
        successful
        messages{
          ...EtheloApi::Fragments::MESSAGES_FRAGMENT
        }
        result {
          ...EtheloApi::Fragments::OPTION_CATEGORY_BIN_VOTE_FRAGMENT
        }
      }
    }
    GRAPHQL

    DELETE_OPTION_CATEGORY_BIN_VOTE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
    mutation(
      $decision_id: ID!
      $id: ID!
    )
    {
      deleteOptionCategoryBinVote(
        input: {
          id: $id
          decisionId: $decision_id
        }
      )
      {
        successful
        messages{
          ...EtheloApi::Fragments::MESSAGES_FRAGMENT
        }
      }
    }
    GRAPHQL

    UPSERT_OPTION_CATEGORY_RANGE_VOTE_FIELDS = %w(decision_id participant_id option_category_id delete high_option_id low_option_id)
    UPSERT_OPTION_CATEGORY_RANGE_VOTE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $participant_id: ID!
        $option_category_id: ID!
        $high_option_id: ID
        $low_option_id: ID!
        $delete: Boolean
      ) {
        upsertOptionCategoryRangeVote(
          input: {
            decisionId: $decision_id
            participantId: $participant_id
            optionCategoryId: $option_category_id
            highOptionId: $high_option_id
            lowOptionId: $low_option_id
            delete: $delete
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_CATEGORY_RANGE_VOTE_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION_CATEGORY_RANGE_VOTE = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteOptionCategoryRangeVote(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPSERT_OPTION_CATEGORY_WEIGHT_FIELDS = %w(decision_id option_category_id participant_id weighting delete)
    UPSERT_OPTION_CATEGORY_WEIGHT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $option_category_id: ID!
        $participant_id: ID!
        $weighting: Int!
        $delete: Boolean
      ) {
        upsertOptionCategoryWeight(
          input: {
            decisionId: $decision_id
            optionCategoryId: $option_category_id
            participantId: $participant_id
            weighting: $weighting
            delete: $delete
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::OPTION_CATEGORY_WEIGHT_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_OPTION_CATEGORY_WEIGHT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteOptionCategoryWeight(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

    UPSERT_CRITERION_WEIGHT_FIELDS = %w(decision_id criterion_id participant_id weighting delete)
    UPSERT_CRITERION_WEIGHT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation (
        $decision_id: ID!
        $criterion_id: ID!
        $participant_id: ID!
        $weighting: Int!
        $delete: Boolean
      ) {
        upsertCriteriaWeight(
          input: {
            decisionId: $decision_id
            criteriaId: $criterion_id
            participantId: $participant_id
            weighting: $weighting
            delete: $delete
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
          result {
            ...EtheloApi::Fragments::CRITERION_WEIGHT_FRAGMENT
          }
        }
      }
    GRAPHQL

    DELETE_CRITERION_WEIGHT = EtheloApi::Runner.prepare_query <<-'GRAPHQL'
      mutation(
        $decision_id: ID!
        $id: ID!
      )
      {
        deleteCriteriaWeight(
          input: {
            id: $id
            decisionId: $decision_id
          }
        )
        {
          successful
          messages{
            ...EtheloApi::Fragments::MESSAGES_FRAGMENT
          }
        }
      }
    GRAPHQL

  end
end
