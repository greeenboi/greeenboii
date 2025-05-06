# frozen_string_literal: true

require_relative "greeenboii/version"
require_relative "libsql"
require "cli/ui"
require "date"
require "console_table"

require "nokogiri"
require "httparty"

require "sqlite3"

require 'json'
require 'net/http'
require 'uri'

require 'dotenv'
require 'fileutils'

module Greeenboii
  class Error < StandardError; end

  class WebsiteBuilder
    def self.build_website
      CLI::UI::Frame.open("{{v}} Website Builder") do
        CLI::UI::Prompt.ask("Choose a template:") do |handler|
          handler.option("{{green:NextJs-CoolStack}}") { |selection| create_nextjs(selection) }
          handler.option("{{yellow:Hono-API}}") { |selection| create_hono(selection) }
          # handler.option("{{blue:Rails}}") { |selection| create_rails(selection) }
        end
      end
    end

    def self.create_nextjs(_selection)
      # Ask for a relative path instead
      location = CLI::UI.ask("Where to install? (relative path)", default: "nextjs-project")
      CLI::UI.puts("Checking prerequisites...")

      # Check prerequisites
      node_version = begin
        `node -v`.strip
      rescue StandardError
        nil
      end
      unless node_version
        CLI::UI.puts(CLI::UI.fmt("{{x}} Node.js not found. Please install Node.js first"))
        return
      end

      git_version = begin
        `git --version`.strip
      rescue StandardError
        nil
      end
      unless git_version
        CLI::UI.puts(CLI::UI.fmt("{{x}} Git not found. Please install Git first"))
        return
      end

      # Create a path relative to current directory
      full_path = File.expand_path(location, Dir.pwd)

      # Check if directory already exists
      if Dir.exist?(full_path)
        # If directory exists, check if it's empty
        unless Dir.empty?(full_path) # . and .. entries
          CLI::UI.puts(CLI::UI.fmt("{{x}} Directory not empty: #{full_path}"))
          return
        end
      else
        # Try to create the directory
        begin
          FileUtils.mkdir_p(full_path)
        rescue StandardError => e
          CLI::UI.puts(CLI::UI.fmt("{{x}} Cannot create directory: #{e.message}"))
          return
        end
      end

      success = false
      CLI::UI::Spinner.spin("Setting up NextJS + Supabase template") do |spinner|
        spinner.update_title("Cloning repository...")

        # Clone directly into the target directory
        clone_cmd = "git clone https://github.com/greeenboi/nextjs-supabase-template.git \"#{full_path}\""
        result = system(clone_cmd)

        unless result
          # Try alternative approach if direct cloning fails
          spinner.update_title("Direct clone failed, trying alternative...")

          # Clone to a temporary directory first
          temp_dir = "#{Dir.pwd}/temp_clone_#{Time.now.to_i}"
          FileUtils.mkdir_p(temp_dir)
          result = system("git clone https://github.com/greeenboi/nextjs-supabase-template.git \"#{temp_dir}\"")

          if result
            # Copy files to destination
            FileUtils.cp_r(Dir.glob("#{temp_dir}/*"), full_path)
            FileUtils.cp_r(Dir.glob("#{temp_dir}/.*").reject { |f| f =~ /\/\.\.?$/ }, full_path)
            FileUtils.rm_rf(temp_dir)
          else
            spinner.update_title("Clone failed")
            next
          end
        end

        spinner.update_title("Installing dependencies...")
        Dir.chdir(full_path) do
          package_manager = if system("bun -v > /dev/null 2>&1")
                              "bun"
                            elsif system("pnpm -v > /dev/null 2>&1")
                              "pnpm"
                            else
                              "npm"
                            end
          spinner.update_title("Installing dependencies with #{package_manager}...")
          system("#{package_manager} install")
        end

        success = true
        spinner.update_title("Setup complete!")
      rescue StandardError => e
        spinner.update_title("Error: #{e.message}")
      end

      if success
        CLI::UI.puts(CLI::UI.fmt("{{v}} NextJS template installed successfully in #{full_path}"))
        CLI::UI.puts(CLI::UI.fmt("{{*}} To start: cd \"#{location}\" && #{system} run dev"))
      else
        CLI::UI.puts(CLI::UI.fmt("{{x}} Installation failed"))
      end
    end

    def self.create_hono(_selection)
      # Ask for a relative path instead
      location = CLI::UI.ask("Where to install? (relative path)", default: "hono-api")
      CLI::UI.puts("Checking prerequisites...")

      # Check prerequisites
      node_version = begin
        `node -v`.strip
      rescue StandardError
        nil
      end
      unless node_version
        CLI::UI.puts(CLI::UI.fmt("{{x}} Node.js not found. Please install Node.js first"))
        return
      end

      git_version = begin
        `git --version`.strip
      rescue StandardError
        nil
      end
      unless git_version
        CLI::UI.puts(CLI::UI.fmt("{{x}} Git not found. Please install Git first"))
        return
      end

      # Check for Deno
      deno_version = begin
        `deno --version`.strip
      rescue StandardError
        nil
      end
      unless deno_version
        CLI::UI.puts(CLI::UI.fmt("{{x}} Deno not found. Please install Deno first"))
        return
      end

      # Create a path relative to current directory
      full_path = File.expand_path(location, Dir.pwd)

      # Check if directory already exists
      if Dir.exist?(full_path)
        # If directory exists, check if it's empty
        unless Dir.empty?(full_path) # . and .. entries
          CLI::UI.puts(CLI::UI.fmt("{{x}} Directory not empty: #{full_path}"))
          return
        end
      else
        # Try to create the directory
        begin
          FileUtils.mkdir_p(full_path)
        rescue StandardError => e
          CLI::UI.puts(CLI::UI.fmt("{{x}} Cannot create directory: #{e.message}"))
          return
        end
      end

      success = false
      CLI::UI::Spinner.spin("Setting up Hono Deno backend template") do |spinner|
        spinner.update_title("Cloning repository...")

        # Clone directly into the target directory
        clone_cmd = "git clone https://github.com/greeenboi/hono-deno-backend-template.git \"#{full_path}\""
        result = system(clone_cmd)

        unless result
          # Try alternative approach if direct cloning fails
          spinner.update_title("Direct clone failed, trying alternative...")

          # Clone to a temporary directory first
          temp_dir = "#{Dir.pwd}/temp_clone_#{Time.now.to_i}"
          FileUtils.mkdir_p(temp_dir)
          result = system("git clone https://github.com/greeenboi/hono-deno-backend-template.git \"#{temp_dir}\"")

          if result
            # Copy files to destination
            FileUtils.cp_r(Dir.glob("#{temp_dir}/*"), full_path)
            FileUtils.cp_r(Dir.glob("#{temp_dir}/.*").reject { |f| f =~ /\/\.\.?$/ }, full_path)
            FileUtils.rm_rf(temp_dir)
          else
            spinner.update_title("Clone failed")
            next
          end
        end

        success = true
        spinner.update_title("Setup complete!")
      rescue StandardError => e
        spinner.update_title("Error: #{e.message}")
      end

      if success
        CLI::UI.puts(CLI::UI.fmt("{{v}} Hono API template installed successfully in #{full_path}"))
        CLI::UI.puts(CLI::UI.fmt("{{*}} To start: cd \"#{location}\" && deno task start"))
      else
        CLI::UI.puts(CLI::UI.fmt("{{x}} Installation failed"))
      end
    end
  end

  class Search
    SEARCH_ENGINES = {
      "Google" => "https://www.google.com/search?client=opera-gx&q= ",
      "Bing" => "https://www.bing.com/search?q=",
      "DuckDuckGo" => "https://duckduckgo.com/?q="
    }.freeze

    def self.perform_search
      query = CLI::UI.ask("Enter your search query:", default: "")
      return if query.empty?

      results = []
      CLI::UI::SpinGroup.new do |spin_group|
        SEARCH_ENGINES.each do |engine, base_url|
          spin_group.add("Searching #{engine}...") do |spinner|
            suffix = case engine
                     when "Google"
                       "&sourceid=opera&ie=UTF-8&oe=UTF-8"
                     when "Bing"
                       "&sp=-1&pq=test&sc=6-4&qs=n&sk=&cvid=#{SecureRandom.hex(16)}"
                     when "DuckDuckGo"
                       "&t=h_&ia=web"
                     end
            search_url = "#{base_url}#{URI.encode_www_form_component(query)}#{suffix}"
            links = scrape_links(engine, search_url)
            results << { engine: engine, links: links }
            sleep 1.0 # Simulating search delay
            spinner.update_title("#{engine} search complete!")
          end
        end
      end

      display_results(results)
    end

    def self.scrape_links(engine, url)
      headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36",
        "Accept-Language" => "en-US,en;q=0.5"
      }

      response = HTTParty.get(url, headers: headers)
      puts "Debug: HTTP Status: #{response.code}"

      doc = Nokogiri::HTML(response.body)
      puts "Debug: Page title: #{doc.title}"

      results = []

      case engine
      when "Google"
        doc.css("div.g").each do |result|
          link = result.css(".yuRUbf > a").first
          next unless link

          title = result.css("h3").text.strip
          url = link["href"]
          result.css(".VwiC3b").text.strip

          puts "Debug: Found Google result - Title: #{title}"
          results << url if url.start_with?("http")
        end

      when "Bing"
        doc.css("#b_results li.b_algo").each do |result|
          link = result.css("h2 a").first
          next unless link

          url = link["href"]
          puts "Debug: Found Bing result - URL: #{url}"
          results << url if url.start_with?("http")
        end

      else # DuckDuckGo
        doc.css(".result__body").each do |result|
          link = result.css(".result__title a").first
          next unless link

          url = link["href"]
          puts "Debug: Found DuckDuckGo result - URL: #{url}"
          results << url if url.start_with?("http")
        end
      end

      puts "Debug: Total results found: #{results.length}"
      results.take(8)
    end

    def self.display_results(results)
      CLI::UI.frame_style = :bracket
      CLI::UI::Frame.open(CLI::UI.fmt("{{green:Search Results}}")) do
        results.each do |result|
          puts CLI::UI.fmt("{{v}} {{cyan:#{result[:engine]}}}")
          result[:links].each_with_index do |link, idx|
            puts CLI::UI.fmt("  {{*}} ##{idx + 1}: #{link}")
          end
        end
      end
    end
  end

  class TodoList
    def initialize
      @db = setup_database
    end

    private def setup_database
      db = SQLite3::Database.new("greeenboii_todo.db")
      db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          completed BOOLEAN DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      SQL
      db
    end

    def add_task
      title = CLI::UI.ask("Enter task title:")
      return if title.empty?

      @db.execute("INSERT INTO todos (title) VALUES (?)", [title])
      puts CLI::UI.fmt "{{green:✓}} Task added successfully!"
    end

    def list_tasks
      tasks = @db.execute("SELECT id, title, completed, created_at FROM todos ORDER BY created_at DESC")
      if tasks.empty?
        puts CLI::UI.fmt "{{yellow:⚠}} No tasks found"
        return
      end

      ConsoleTable.define(%w[ID Title Status Created]) do |table|
        tasks.each do |id, title, completed, created_at|
          status = completed == 1 ? "{{green:✓}} Done" : "{{red:✗}} Pending"
          table << [id, title, CLI::UI.fmt(status), created_at]
        end
      end
    end

    def mark_done
      list_tasks
      id = CLI::UI.ask("Enter task ID to mark as done:")
      return if id.empty?

      @db.execute("UPDATE todos SET completed = 1 WHERE id = ?", [id])
      puts CLI::UI.fmt "{{green:✓}} Task marked as done!"
    end

    def delete_task
      list_tasks
      id = CLI::UI.ask("Enter task ID to delete:")
      return if id.empty?

      @db.execute("DELETE FROM todos WHERE id = ?", [id])
      puts CLI::UI.fmt "{{green:✓}} Task deleted!"
    end

    def update_task
      list_tasks
      id = CLI::UI.ask("Enter task ID to update:")
      return if id.empty?

      title = CLI::UI.ask("Enter new title:")
      return if title.empty?

      @db.execute("UPDATE todos SET title = ? WHERE id = ?", [title, id])
      puts CLI::UI.fmt "{{green:✓}} Task updated!"
    end

    def show_menu
      CLI::UI::Frame.divider("{{v}} Todo List")
      loop do
        CLI::UI::Prompt.ask("Todo List Options:") do |handler|
          handler.option("List Tasks")   { list_tasks }
          handler.option("Add Task")     { add_task }
          handler.option("Mark Done")    { mark_done }
          handler.option("Update Task")  { update_task }
          handler.option("Delete Task")  { delete_task }
          handler.option("Exit")         { return }
        end
      end
    end
  end

  class GistManager
    def initialize
      Dotenv.load
      ensure_connection
    end

    private def ensure_connection
      return if ENV['TURSO_DATABASE_URL'] && ENV['TURSO_AUTH_TOKEN']

      CLI::UI.puts(CLI::UI.fmt("{{yellow:⚠}} Turso credentials not found"))
      manage_credentials
    end

    def add_gist
      unless ENV['TURSO_DATABASE_URL'] && ENV['TURSO_AUTH_TOKEN']
        CLI::UI.puts(CLI::UI.fmt("{{red:✗}} Cloud credentials required"))
        return
      end

      title = CLI::UI.ask("Enter a title for this gist:")
      return if title.empty?

      url = CLI::UI.ask("Enter GitHub Gist URL:")
      return if url.empty? || !url.match?(/https:\/\/gist\.github\.com\//)

      description = CLI::UI.ask("Enter a description (optional):", default: "")
      tags = CLI::UI.ask("Enter tags (comma separated):", default: "")

      # Extract gist ID from URL
      gist_id = url.split('/').last
      created_at = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      CLI::UI::Spinner.spin("Saving gist...") do |spinner|
        begin
          # First create table if needed
          create_table_result = turso_execute(
            "CREATE TABLE IF NOT EXISTS gists (gist_id TEXT PRIMARY KEY, title TEXT NOT NULL, url TEXT NOT NULL, description TEXT, tags TEXT, created_at TEXT)"
          )

          # Then insert the data
          insert_result = turso_execute(
            "INSERT OR REPLACE INTO gists (gist_id, title, url, description, tags, created_at) VALUES (?, ?, ?, ?, ?, ?)",
            [gist_id, title, url, description, tags, created_at]
          )

          spinner.update_title("Gist saved successfully")
        rescue => e
          spinner.update_title("Error saving gist: #{e.message}")
        end
      end
    end

    def list_gists
      unless ENV['TURSO_DATABASE_URL'] && ENV['TURSO_AUTH_TOKEN']
        CLI::UI.puts(CLI::UI.fmt("{{red:✗}} Cloud credentials required"))
        return
      end

      CLI::UI::Spinner.spin("Fetching gists...") do |spinner|
        begin
          # Create table if needed
          create_table_result = turso_execute(
            "CREATE TABLE IF NOT EXISTS gists (gist_id TEXT PRIMARY KEY, title TEXT NOT NULL, url TEXT NOT NULL, description TEXT, tags TEXT, created_at TEXT)"
          )

          # Get all gists
          result = turso_execute(
            "SELECT gist_id, title, url, description, tags, created_at FROM gists ORDER BY created_at DESC"
          )

          @gists = extract_rows(result)

          if @gists.empty?
            spinner.update_title("No gists found")
          else
            spinner.update_title("Found #{@gists.length} gists")
          end
        rescue => e
          spinner.update_title("Error fetching gists: #{e.message}")
        end
      end

      return if !@gists || @gists.empty?

      CLI::UI.puts("\nYour Gists:")
      @gists.each do |gist|
        gist_id, title, url, description, tags, created_at = gist
        CLI::UI.puts(CLI::UI.fmt("{{cyan:#{gist_id}}}: {{bold:#{title}}} - #{url}"))
        CLI::UI.puts(CLI::UI.fmt("   Description: #{description}")) if description && !description.empty?
        CLI::UI.puts(CLI::UI.fmt("   Tags: #{tags}")) if tags && !tags.empty?
        CLI::UI.puts(CLI::UI.fmt("   Created: #{created_at}"))
        CLI::UI.puts("")
      end
    end

    def search_gists
      unless ENV['TURSO_DATABASE_URL'] && ENV['TURSO_AUTH_TOKEN']
        CLI::UI.puts(CLI::UI.fmt("{{red:✗}} Cloud credentials required"))
        return
      end

      term = CLI::UI.ask("Enter search term:")
      return if term.empty?

      CLI::UI::Spinner.spin("Searching gists...") do |spinner|
        begin
          result = turso_execute(
            "SELECT gist_id, title, url, description, tags, created_at FROM gists WHERE title LIKE ? OR description LIKE ? OR tags LIKE ? ORDER BY created_at DESC",
            ["%#{term}%", "%#{term}%", "%#{term}%"]
          )

          @search_results = extract_rows(result)

          if @search_results.empty?
            spinner.update_title("No matching gists found")
          else
            spinner.update_title("Found #{@search_results.length} matching gists")
          end
        rescue => e
          spinner.update_title("Search error: #{e.message}")
        end
      end

      return if !@search_results || @search_results.empty?

      CLI::UI.puts(CLI::UI.fmt("\n{{bold:Search Results:}}"))
      @search_results.each do |gist|
        gist_id, title, url, description, tags, created_at = gist
        CLI::UI.puts(CLI::UI.fmt("{{cyan:#{gist_id}}}: {{bold:#{title}}} - #{url}"))
        CLI::UI.puts(CLI::UI.fmt("   Description: #{description}")) if description && !description.empty?
        CLI::UI.puts(CLI::UI.fmt("   Tags: #{tags}")) if tags && !tags.empty?
        CLI::UI.puts(CLI::UI.fmt("   Created: #{created_at}"))
        CLI::UI.puts("")
      end
    end

    def open_gist
      list_gists

      return if !@gists || @gists.empty?

      gist_id = CLI::UI.ask("Enter gist ID to open:")
      return if gist_id.empty?

      # Find the matching gist
      gist = @gists.find { |g| g[0] == gist_id }

      unless gist
        CLI::UI.puts(CLI::UI.fmt("{{red:✗}} Gist not found"))
        return
      end

      url = gist[2] # URL is at index 2

      if RUBY_PLATFORM.match?(/mswin|mingw|cygwin/)
        system("start #{url}")
      elsif RUBY_PLATFORM.match?(/darwin/)
        system("open #{url}")
      elsif RUBY_PLATFORM.match?(/linux/)
        system("xdg-open #{url}")
      else
        CLI::UI.puts(CLI::UI.fmt("{{yellow:⚠}} Couldn't determine how to open URL on your platform. URL: #{url}"))
      end
    end

    def delete_gist
      list_gists

      return if !@gists || @gists.empty?

      gist_id = CLI::UI.ask("Enter gist ID to delete:")
      return if gist_id.empty?

      CLI::UI::Spinner.spin("Deleting gist...") do |spinner|
        begin
          result = turso_execute("DELETE FROM gists WHERE gist_id = ?", [gist_id])

          # Try to determine if rows were affected
          affected_rows = get_affected_rows(result)

          if affected_rows > 0
            spinner.update_title("Gist deleted successfully")
          else
            spinner.update_title("Gist not found")
          end
        rescue => e
          spinner.update_title("Error deleting gist: #{e.message}")
        end
      end
    end

    def manage_credentials
      CLI::UI::Frame.divider("{{v}} Cloud Credentials")

      current_url = ENV['TURSO_DATABASE_URL'] || "Not set"
      current_token = ENV['TURSO_AUTH_TOKEN'] ? "[Hidden]" : "Not set"

      CLI::UI.puts(CLI::UI.fmt("Current settings:"))
      CLI::UI.puts(CLI::UI.fmt("Database URL: {{cyan:#{current_url}}}"))
      CLI::UI.puts(CLI::UI.fmt("Auth Token: {{cyan:#{current_token}}}"))
      CLI::UI.puts("")

      CLI::UI::Prompt.ask("Credential Options:") do |handler|
        handler.option("Update Database URL") do
          url = CLI::UI.ask("Enter Turso Database URL:")
          update_env_file('TURSO_DATABASE_URL', url) unless url.empty?
        end

        handler.option("Update Auth Token") do
          token = CLI::UI.ask("Enter Turso Auth Token:")
          update_env_file('TURSO_AUTH_TOKEN', token) unless token.empty?
        end

        handler.option("Test Connection") do
          test_connection
        end

        handler.option("Back") { return }
      end
    end

    private def update_env_file(key, value)
      env_file = '.env'

      # Read existing .env content
      content = File.exist?(env_file) ? File.read(env_file) : ""
      lines = content.split("\n")

      # Find and replace the line with the key, or add it
      key_found = false
      lines.map! do |line|
        if line.start_with?("#{key}=")
          key_found = true
          "#{key}=#{value}"
        else
          line
        end
      end

      lines << "#{key}=#{value}" unless key_found

      # Write back to file
      File.write(env_file, lines.join("\n"))

      # Reload environment
      ENV[key] = value

      CLI::UI.puts(CLI::UI.fmt("{{v}} Updated #{key} in .env file"))
    end

    private def test_connection
      CLI::UI::Spinner.spin("Testing Turso connection...") do |spinner|
        begin
          unless ENV['TURSO_DATABASE_URL'] && ENV['TURSO_AUTH_TOKEN']
            spinner.update_title("Cloud credentials not found")
            next
          end

          result = turso_execute("SELECT 1")
          spinner.update_title("Connection successful!")
        rescue => e
          spinner.update_title("Connection failed: #{e.message}")
        end
      end
    end

    def show_menu
      CLI::UI::Frame.divider("{{v}} Gist Manager")
      loop do
        CLI::UI::Prompt.ask("Gist Manager Options:") do |handler|
          handler.option("Add Gist")          { add_gist }
          handler.option("List Gists")        { list_gists }
          handler.option("Search Gists")      { search_gists }
          handler.option("Open Gist")         { open_gist }
          handler.option("Delete Gist")       { delete_gist }
          handler.option("Cloud Settings")    { manage_credentials }
          handler.option("Exit")              { return }
        end
      end
    end

    private def turso_execute(sql, params = [])
      url = ENV['TURSO_DATABASE_URL']
      auth_token = ENV['TURSO_AUTH_TOKEN']

      # Ensure URL has the correct endpoint path for v2 pipeline
      url = url.end_with?('/v2/pipeline') ? url : "#{url}/v2/pipeline"

      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{auth_token}"
      request["Content-Type"] = "application/json"

      # Format parameters into the required format
      formatted_params = params.map do |param|
        type = case param
               when Integer, /^\d+$/
                 "integer"
               when Float, /^\d+\.\d+$/
                 "float"
               when TrueClass, FalseClass, /^(true|false)$/i
                 "boolean"
               when NilClass
                 "null"
               else
                 "text"
               end

        {
          "type": type,
          "value": param.to_s
        }
      end

      # Build the request body
      stmt = {
        "sql": sql,
        "args": formatted_params
      }

      payload = {
        "requests": [
          { "type": "execute", "stmt": stmt },
          { "type": "close" }
        ]
      }

      request.body = JSON.generate(payload)

      begin
        # Log the request for debugging
        ensure_log_directory
        File.open('logs/turso_requests.log', 'a') do |f|
          f.puts "#{Time.now} - REQUEST to #{uri}"
          f.puts "SQL: #{sql}"
          f.puts "Params: #{params.inspect}"
          f.puts "Formatted Params: #{formatted_params.inspect}"
          f.puts "Payload: #{payload.to_json}"
          f.puts "-" * 80
        end

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        # Log the response
        ensure_log_directory
        File.open('logs/turso_responses.log', 'a') do |f|
          f.puts "#{Time.now} - RESPONSE (#{response.code})"
          f.puts "Body: #{response.body}"
          f.puts "-" * 80
        end

        if response.code != "200"
          error_msg = "HTTP error: #{response.code} - #{response.body}"
          log_error(error_msg)
          raise error_msg
        end

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        error_msg = "JSON parse error: #{e.message}. Response body: #{response&.body}"
        log_error(error_msg)
        raise error_msg
      rescue => e
        error_msg = "Query failed: #{e.message}"
        log_error(error_msg)
        raise error_msg
      end
    end

    private def log_error(message)
      ensure_log_directory
      File.open('logs/turso_errors.log', 'a') do |f|
        f.puts "#{Time.now} - ERROR"
        f.puts message
        f.puts "-" * 80
      end
      # Also output to console
      CLI::UI.puts(CLI::UI.fmt("{{red:ERROR}}: #{message}"))
    end

    private def ensure_log_directory
      FileUtils.mkdir_p('logs') unless Dir.exist?('logs')
    end

    private def extract_rows(result)
      rows = []

      if result &&
         result["results"] &&
         result["results"][0] &&
         result["results"][0]["type"] == "ok" &&
         result["results"][0]["response"] &&
         result["results"][0]["response"]["type"] == "execute" &&
         result["results"][0]["response"]["result"]

        result_data = result["results"][0]["response"]["result"]

        if result_data["rows"]
          rows = result_data["rows"]
        end
      end

      rows
    end

    private def get_affected_rows(result)
      if result &&
         result["results"] &&
         result["results"][0] &&
         result["results"][0]["type"] == "ok" &&
         result["results"][0]["response"] &&
         result["results"][0]["response"]["type"] == "execute" &&
         result["results"][0]["response"]["result"] &&
         result["results"][0]["response"]["result"]["affected_row_count"]

        return result["results"][0]["response"]["result"]["affected_row_count"]
      end

      0
    end
  end

  class Options
    def self.show_options
      CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY

      CLI::UI::Prompt.ask("Choose an option:") do |handler|
        handler.option("{{gray:Search Files}}") { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{gray:Search Directory}}") { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{green:Website Builder}}") { |_selection| WebsiteBuilder.build_website }
        handler.option("{{yellow:Todo List}}") { |_selection| TodoList.new.show_menu }
        handler.option("{{cyan:Search Engine}}") { |_selection| Search.perform_search }
        handler.option("{{blue:Gist Manager}}") { |_selection| GistManager.new.show_menu }
        handler.option("{{red:Exit}}") { |_selection| exit }
      end
    end
  end

  class Main
    CLI::UI::StdoutRouter.enable
    current_time = DateTime.now.strftime("%d-%m-%Y %H:%M:%S")
    CLI::UI::Frame.open("{{v}} Greeenboi : #{current_time}") do
      puts "Welcome to Greeenboii"
      puts "Lets do some magic!"
      CLI::UI.frame_style = :bracket
      CLI::UI::Frame.open(CLI::UI.fmt("{{green:Welcome to Greeenboii CLI}}")) do
        puts CLI::UI.fmt("{{cyan:Version}}: #{Greeenboii::VERSION}")
        # ConsoleTable.define(%w[Name Version]) do |table|
        #   table << ["Greeenboii", Greeenboii::VERSION]
        # end
        puts CLI::UI.fmt("{{yellow:Type 'help' to see available commands}}")
        Options.show_options
      end
    end
  end
end
