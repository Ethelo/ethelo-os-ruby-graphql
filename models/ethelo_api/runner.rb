require 'graphql/client/http'

module EtheloApi
  class Runner

    class << self
      def client(endpoint_category = :default)
        @client_cache ||= {}
        return @client_cache[endpoint_category] if @client_cache.has_key?(endpoint_category)

        config = Rails.application.config_for(:ethelo_api)
        if config[endpoint_category.to_s].present? 
          config.merge!(config[endpoint_category.to_s])
        end

        schema_path = Rails.root.join(config['schema']).to_s

        # URLs can be overridden with environment variables
        url = ENV["API_#{endpoint_category.upcase}_URL"] ||
              ENV["API_URL"] ||
              config['url']

        @client_cache[endpoint_category] = GraphQL::Client.new(
          schema: schema_path,
          execute: GraphQL::Client::HTTP.new(url) do
            def connection
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = uri.scheme == 'https'
              http.tap do |client|
                # group results can take a long time - 1 week timeout on the group results server
                using_group_results_server = ENV['API_GROUP_RESULTS_URL'].present? && @uri.to_s.include?(ENV['API_GROUP_RESULTS_URL'])
                client.read_timeout = using_group_results_server ? 7*86400 : 60
              end
            end
          end
        )
      end

      def run_query(query_object, variables = {}, endpoint_category = :default)
        client(endpoint_category).query(query_object, variables: variables)
      end

      def prepare_query(string)
        client.parse(string)
      end

      def write_tmp_schema(sorted)
        return nil if sorted.blank?
        file = File.open(Rails.root.join('tmp/schema.json'), 'w+')
        begin
          file.write(JSON.pretty_generate(sorted))
        ensure
          file.close
        end
        File.absolute_path(file)
      end

      def sort_by_name(list)
        return list unless list.respond_to? :sort_by
        list.sort_by { |f| f['name'] }
      end

      # sorts schema keys by name so they are easier to diff when checking in schema changes
      # does not override the file - updated schema must be manually copied to ethelo_api.json
      def sort_schema
        schema = Rails.root.join(Rails.application.config_for(:ethelo_api)['schema']).to_s
        json = JSON.parse(File.read(schema))

        json['data']['__schema']['types'] = sort_by_name(json['data']['__schema']['types'])
        json['data']['__schema']['types'].map! do |t|
          t['fields'] = sort_by_name(t['fields'])
          t['inputFields'] = sort_by_name(t['inputFields'])
          t
        end

        write_tmp_schema(json)
      end

    end
  end

end
