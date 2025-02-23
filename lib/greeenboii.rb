# frozen_string_literal: true

require_relative "greeenboii/version"
require 'cli/ui'

module Greeenboii
  class Error < StandardError; end
  class Main
    CLI::UI::StdoutRouter.enable
    CLI::UI::Frame.open('Frame 1') do
      CLI::UI.frame_style = :bracket
      CLI::UI::Frame.open('Frame 2') { puts "inside frame 2" }
      puts "inside frame 1"
    end
  end
end
