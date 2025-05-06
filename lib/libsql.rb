# lib/libsql.rb
require 'net/http'
require 'json'
require 'uri'
require 'dotenv'

module Libsql
  class Database
    def initialize(url:, auth_token:)
      # Ensure URL has the correct endpoint path
      @url = url.end_with?('/v2/pipeline') ? url : "#{url}/v2/pipeline"
      @auth_token = auth_token
    end

    def connect
      connection = Connection.new(@url, @auth_token)
      yield connection if block_given?
      connection
    end
  end

  class Connection
    def initialize(url, auth_token)
      @url = url
      @auth_token = auth_token
      @last_changes = 0
    end

    def execute(query, *params)
      params = params.flatten if params.is_a?(Array)
      execute_stmt(query, params)
    end

    def execute_batch(batch_query)
      # Split the batch query into individual statements
      statements = batch_query.split(';').map(&:strip).reject(&:empty?)

      requests = statements.map do |stmt|
        { "type" => "execute", "stmt" => { "sql" => stmt } }
      end

      # Add close request at the end
      requests << { "type" => "close" }

      execute_pipeline(requests)
    end

    def query(query, *params)
      params = params.flatten if params.is_a?(Array)
      result = execute_stmt(query, params)
      QueryResult.new(result)
    end

    def changes
      @last_changes
    end

    private

    def execute_stmt(sql, params)
      requests = [
        { "type" => "execute", "stmt" => { "sql" => sql, "args" => params } },
        { "type" => "close" }
      ]

      execute_pipeline(requests)
    end

    def execute_pipeline(requests)
      uri = URI(@url)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@auth_token}"
      request["Content-Type"] = "application/json"

      request.body = JSON.generate({
        "requests" => requests
      })

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      if response.code != "200"
        raise "Query failed: #{response.body}"
      end

      response_data = JSON.parse(response.body)

      # Extract the affected row count for UPDATE/DELETE operations
      if response_data["results"] &&
         response_data["results"][0] &&
         response_data["results"][0]["type"] == "ok" &&
         response_data["results"][0]["response"] &&
         response_data["results"][0]["response"]["type"] == "execute" &&
         response_data["results"][0]["response"]["result"] &&
         response_data["results"][0]["response"]["result"]["affected_row_count"]
        @last_changes = response_data["results"][0]["response"]["result"]["affected_row_count"]
      end

      response_data
    end
  end

  class QueryResult
    def initialize(result)
      @result = result

      # Extract columns and rows from Turso's format
      if @result["results"] &&
         @result["results"][0] &&
         @result["results"][0]["type"] == "ok" &&
         @result["results"][0]["response"] &&
         @result["results"][0]["response"]["type"] == "execute" &&
         @result["results"][0]["response"]["result"]

        result_data = @result["results"][0]["response"]["result"]
        @columns = result_data["cols"] || []
        @rows = result_data["rows"] || []
      else
        @columns = []
        @rows = []
      end
    end

    def empty?
      @rows.empty?
    end

    def to_a
      @rows
    end

    def close
      # No-op for HTTP API
    end
  end

  # Helper method to create a database connection using .env credentials
  def self.connect_with_env
    Dotenv.load

    # Check for required environment variables
    unless ENV['TURSO_DATABASE_URL'] && ENV['TURSO_AUTH_TOKEN']
      raise "Missing TURSO_DATABASE_URL or TURSO_AUTH_TOKEN in .env file"
    end

    db = Database.new(
      url: ENV['TURSO_DATABASE_URL'],
      auth_token: ENV['TURSO_AUTH_TOKEN']
    )

    # If a block is given, yield connection
    if block_given?
      db.connect { |conn| yield conn }
    else
      db
    end
  end
end