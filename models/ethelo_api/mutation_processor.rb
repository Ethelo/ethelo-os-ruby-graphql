module EtheloApi

  class MutationProcessor < EtheloApi::QueryProcessor
    include SemanticLogger::Loggable
    
    def initialize(target, result)
      super(result)
      @target = target
    end

    def process
      if @result[:data].nil?
        #TODO better error handling on bad graphql
        logger.error(@result[:errors].to_a.join[', '])
        @target.errors.add(:base, 'Unexpected error, please try again')
      else
        response = @result[:data].values.first # key name will change based on mutation.
        if response[:successful]
          if response[:result].present?

            @target.id = response[:result][:id] unless @target.id.present? && @target.id != 0

            values = response[:result] || {}
            values.each do |key, value|
              if key != :id && @target.respond_to?("#{key}=")
                @target.send("#{key}=", value)
              end
            end
          end

        else
          messages = remap_error_keys(response[:messages])
          messages.each do |message|
            @target.errors.add(message[:field], message[:message])
          end
        end
      end

      @target
    end

    def remap_error_keys(messages)
      return [] if messages.blank?
      messages.map { |message|
        message[:field] = ['id', 'form'].include?(message[:field]) ? 'base' : message[:field]
        message[:field] = message[:field].underscore.gsub(/^(.*)_id$/, 'cached_\1_id')
        message
      }
    end
  end
end
