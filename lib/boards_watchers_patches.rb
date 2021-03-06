# use require_dependency if you plan to utilize development mode
require_dependency 'application_helper'
require 'logger'

module BoardsWatchers
  module Patches
    module ApplicationHelperPatch
      def self.included(base) # :nodoc:
        # sending instance methods to module
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          # aliasing methods if needed
          #alias_method_chain :render_page_hierarchy, :watchers
        end
      end

      # Instance methods are here
      module InstanceMethods
        def render_page_hierarchy_with_watchers(pages, node=nil, options={})
          # our code is here
        end
      end
    end
  end

  class << self

    def logger
      @logger ||= BoardsWatchers::Log.init_logs!
    end

  end

  class Log < Logger

    class << self

      def init_logs!
        logfile = Rails.root.join('log', 'mail_reminder.log')
        logger = new(logfile)
        logger.progname = 'BoardsWatchers'
        logger.level = Logger::INFO
        logger.formatter = proc do |severity, time, progname, msg|
          "#{time} [#{severity}] #{msg}\n"
        end
        logger
      end

    end

  end
end

# now we should include this module in ApplicationHelper module
unless ApplicationHelper.included_modules.include? BoardsWatchers::Patches::ApplicationHelperPatch
    ApplicationHelper.send(:include, BoardsWatchers::Patches::ApplicationHelperPatch)
end
