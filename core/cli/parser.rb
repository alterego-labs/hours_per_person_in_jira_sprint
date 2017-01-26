require 'optparse'
require_relative './options.rb'

module CLI
  class Parser
    def self.parse(options)
      args = Options.new(nil, nil)

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: example.rb [options]"

        opts.on("-bBOARD", "--board=BOARD", "An ID of a board") do |board|
          args.board = board.to_i
        end

        opts.on("-sSPRINT", "--sprint=SPRINT", "An ID of a sprint") do |sprint|
          args.sprint = sprint.to_i
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end
      end

      opt_parser.parse!(options)
      return args
    end
  end
end
