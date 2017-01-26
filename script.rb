require "net/https"
require "uri"
require 'json'

require 'pry-nav'
require 'rb-readline'
require 'terminal-table'
require 'virtus'

require_relative './core/http_requester.rb'
require_relative './core/data/issue_assignee.rb'
require_relative './core/data/issue_type.rb'
require_relative './core/data/issue_time_tracking.rb'
require_relative './core/data/issue_fields.rb'
require_relative './core/data/issue.rb'
require_relative './core/data/board.rb'
require_relative './core/data/sprint.rb'

require_relative './core/cli/parser.rb'

USER_LOGIN = ENV['JIRA_USER_LOGIN']
USER_PASSWORD = ENV['JIRA_USER_PASSWORD']
JIRA_DOMAIN = ENV['JIRA_DOMAIN']

cli_options = begin
                CLI::Parser.parse ARGV
              rescue OptionParser::InvalidArgument => e
                puts "Invalid CLI options are passed! Original exception message: #{e.message}"
                puts "Please, run `./run.sh --help` first to see all available options."
                exit
              end

# Choose a board

BOARD_LIST_URL = "https://#{JIRA_DOMAIN}/rest/agile/1.0/board"

boards_json = HttpRequester.new(BOARD_LIST_URL).get_json_response
boards = boards_json['values'].map { |board_json| Board.new(board_json) }

puts "==> Choose a board:"

boards.each do |board|
  puts "   ID: #{board.id}; Name: #{board.name}"
end

puts ''

puts "   Enter an ID:"

selected_board_id = nil

if cli_options.board_set?
  puts cli_options.board
  selected_board_id = cli_options.board
else
  selected_board_id = gets.strip
end

abort('Unknown board!') unless boards.map{ |board| board.id }.include?(selected_board_id.to_i)

puts ''

SPRINT_LIST_URL = "https://#{JIRA_DOMAIN}/rest/agile/1.0/board/#{selected_board_id}/sprint?state=active,future"

sprints_json = HttpRequester.new(SPRINT_LIST_URL).get_json_response
sprints = sprints_json['values'].map { |sprint_json| Sprint.new(sprint_json) }

puts "==> Choose an active or future sprint:"

sprints.each do |sprint|
  puts "   ID: #{sprint.id}; State: #{sprint.state}; Name: #{sprint.name}"
end

puts ''

puts "   Enter an ID:"

selected_sprint_id = nil

if cli_options.sprint_set?
  puts cli_options.sprint
  selected_sprint_id = cli_options.sprint
else
  selected_sprint_id = gets.strip
end

abort('Unknown sprint!') unless sprints.map{ |sprint| sprint.id }.include?(selected_sprint_id.to_i)

SPRINT_ISSUES_URL = "https://#{JIRA_DOMAIN}/rest/agile/1.0/board/#{selected_board_id}/sprint/#{selected_sprint_id}/issue"

issues_json = HttpRequester.new(SPRINT_ISSUES_URL).get_paginated_json_response('issues')
issues = issues_json['values'].map { |issue_json| Issue.new(issue_json) }

subtasks = issues.select { |issue| issue.subtask? || !issue.has_subtasks? }.compact

subtasks_grouped_by_assignee = subtasks.group_by { |subtask| subtask.assignee_name }

time_in_sprint_per_person = subtasks_grouped_by_assignee.reduce([]) do |array, (assignee, subtasks)|
  original_hours= subtasks.reduce(0) { |sum, subtask| sum += subtask.original_estimate_hours }
  spent_hours = subtasks.reduce(0) { |sum, subtask| sum += subtask.time_spent_hours }
  remaining_hours = subtasks.reduce(0) { |sum, subtask| sum += subtask.remaining_estimate_hours }
  array << [assignee, original_hours, spent_hours, remaining_hours]
  array
end

table = Terminal::Table.new
table.title = 'Hours per person in sprint'
table.headings = ['Person', 'Original Hours', 'Spent Hours', 'Remaining Hours']
table.rows = time_in_sprint_per_person
table.align_column(1, :right)
table.align_column(2, :right)
table.align_column(3, :right)

puts table

if subtasks_grouped_by_assignee.fetch('Unknown', []).count > 0
  unassigned_subtasks_keys = subtasks_grouped_by_assignee['Unknown'].map { |subtask| [subtask.key, subtask.original_estimate_hours] }

  table = Terminal::Table.new
  table.title = 'List of unassigned subtasks'
  table.headings = ['Task key', 'Estimate']
  table.rows = unassigned_subtasks_keys
  table.style = {width: 40}

  puts ''
  
  puts table
end
