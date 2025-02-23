# frozen_string_literal: true

require_relative "greeenboii/version"
require 'cli/ui'
require 'date'

module Greeenboii
  class Error < StandardError; end

  class Options
    def self.show_options
      CLI::UI::Prompt.instructions_color = CLI::UI::Color::GRAY

      CLI::UI::Prompt.ask('Choose an option:') do |handler|
        handler.option('{{magenta:Search Files}}')    { |selection| puts "Selected: #{selection}" }
        handler.option('{{blue:Search Directory}}')   { |selection| puts "Selected: #{selection}" }
        handler.option('{{green:Search Content}}')    { |selection| puts "Selected: #{selection}" }
        handler.option('{{yellow:Search History}}')   { |selection| puts "Selected: #{selection}" }
        handler.option('{{cyan:Search Tags}}')        { |selection| puts "Selected: #{selection}" }
        handler.option('{{red:Exit}}')               { |selection| exit }
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
      CLI::UI::Frame.open(CLI::UI.fmt('{{green:Welcome to Greeenboii CLI}}')) do
        puts CLI::UI.fmt("{{cyan:Version}}: #{Greeenboii::VERSION}")
        puts CLI::UI.fmt("{{yellow:Type 'help' to see available commands}}")
        Options.show_options
      end
    end
  end
end
