# frozen_string_literal: true

require_relative "greeenboii/version"
require 'cli/ui'

module Greeenboii
  class Error < StandardError; end
  class Main
    CGI::UI::StdoutRouter.enable
    CGI::UI::Frame.open('Frame 1') do
      CGI::UI.frame_style = :bracket
      CGI::UI::Frame.open('Frame 2') { puts "inside frame 2" }
      puts "inside frame 1"
    end
  end
end
