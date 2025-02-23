# frozen_string_literal: true

require_relative "greeenboii/version"
require "cli/ui"
require "date"
require "console_table"

require "nokogiri"
require "httparty"

module Greeenboii
  class Error < StandardError; end

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
          snippet = result.css(".VwiC3b").text.strip

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

  class Options
    def self.show_options
      CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY

      CLI::UI::Prompt.ask("Choose an option:") do |handler|
        handler.option("{{gray:Search Files}}")    { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{gray:Search Directory}}")   { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{gray:Search Content}}")    { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{gray:Search History}}")   { |selection| puts "Placeholder, Replaced soon. #{selection}" }
        handler.option("{{cyan:Network Search}}")    { |_selection| Search.perform_search }
        handler.option("{{red:Exit}}")               { |_selection| exit }
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
