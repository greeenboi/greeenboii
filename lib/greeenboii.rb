# frozen_string_literal: true

require_relative "greeenboii/version"
require "cli/ui"
require "date"
require "console_table"

require "nokogiri"
require "httparty"

require "sqlite3"

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

  class Options
    def self.show_options
      CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY

      CLI::UI::Prompt.ask("Choose an option:") do |handler|
        handler.option("{{gray:Search Files}}") { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{gray:Search Directory}}") { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{green:Website Builder}}") { |_selection| WebsiteBuilder.build_website }
        handler.option("{{yellow:Todo List}}") { |_selection| TodoList.new.show_menu }
        handler.option("{{cyan:Search Engine}}") { |_selection| Search.perform_search }
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
