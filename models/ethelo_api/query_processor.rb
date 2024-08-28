module EtheloApi

  class QueryProcessor
    include SemanticLogger::Loggable

    def initialize(raw)
      @raw = raw
      @result = result_to_symbolized_hash(raw)
    end

    # returns a hash with all snake case, symbolized keys
    def result_to_symbolized_hash(query_result)
      hash = query_result.to_h.dup

      hash.deep_transform_keys do |key|
        k = key.to_s.underscore rescue key
        k.to_sym rescue key
      end
    end

    def process
      if @result[:data].nil? #graphql error
        Rails.logger.error( "graphql fail")
        {decision:  {meta: {successful: false, completedAt: Time.current }}}
      else
        @result[:data]
      end
    end
  end
end
