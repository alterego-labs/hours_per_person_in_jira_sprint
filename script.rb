require "net/https"
require "uri"
require 'json'

require 'pry-nav'
require 'rb-readline'
require 'terminal-table'
require 'virtus'

USER_LOGIN = ENV['JIRA_USER_LOGIN']
USER_PASSWORD = ENV['JIRA_USER_PASSWORD']
JIRA_DOMAIN = ENV['JIRA_DOMAIN']

class Assignee
  include Virtus.model

  attribute :name, String, default: 'Unknown'
end

class IssueType
  include Virtus.model

  attribute :subtask, Axiom::Types::Boolean, default: false

  def subtask?
    subtask == true
  end
end

class IssueTimeTracking
  include Virtus.model

  attribute :originalEstimateSeconds, Integer, default: 0
  attribute :remainingEstimateSeconds, Integer, default: 0
  attribute :timeSpentSeconds, Integer, default: 0

  def original_estimate_hours
    originalEstimateSeconds.to_i / 3600.0
  end

  def remaining_estimate_hours
    remainingEstimateSeconds.to_i / 3600.0
  end

  def time_spent_hours
    timeSpentSeconds.to_i / 3600.0
  end
end

class IssueFields
  include Virtus.model

  attribute :subtasks
  attribute :assignee, Assignee
  attribute :issuetype, IssueType
  attribute :timetracking, IssueTimeTracking
end

class Issue
  include Virtus.model

  attribute :fields, IssueFields
  attribute :key, String

  def subtask?
    (fields.issuetype || IssueType.new).subtask?
  end

  def has_subtasks?
    fields.subtasks.any?
  end

  def assignee_name
    (fields.assignee || Assignee.new).name
  end

  def original_estimate_hours
    safe_time_tracking.original_estimate_hours
  end

  def remaining_estimate_hours
    safe_time_tracking.remaining_estimate_hours
  end

  def time_spent_hours
    safe_time_tracking.time_spent_hours
  end

  private

  def safe_time_tracking
    fields.timetracking || IssueTimeTracking.new
  end
end

class Board
  include Virtus.model

  attribute :id
  attribute :name
end

class Sprint
  include Virtus.model

  attribute :id
  attribute :name
  attribute :state
end

class HttpRequester
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def get_json_response
    make_http_request
  end

  def get_paginated_json_response(values_key)
    responses = do_paginated_json_response(0, [])
    responses.compact.reduce({'values' => []}) do |hash, response|
      hash['values'] += response.fetch(values_key, [])
      hash
    end
  end

  def do_paginated_json_response(offset, responses)
    response = make_http_request(offset)
    max_results = response['maxResults'].to_i
    total = response['total'].to_i
    start_at = response['startAt'].to_i
    responses = responses + [response]
    if max_results + start_at >= total
      responses
    else
      do_paginated_json_response(offset + 50, responses)
    end
  end

  def make_http_request(start_at = 0)
    uri = URI.parse(url)
    uri.query = URI.encode_www_form("startAt" => start_at) if start_at != 0
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(USER_LOGIN, USER_PASSWORD)
    response = http.request(request)
    JSON.parse(response.body)
  end
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

BOARD_ID = gets.strip

abort('Unknown board!') unless boards.map{ |board| board.id }.include?(BOARD_ID.to_i)

puts ''

SPRINT_LIST_URL = "https://#{JIRA_DOMAIN}/rest/agile/1.0/board/#{BOARD_ID}/sprint?state=active,future"

sprints_json = HttpRequester.new(SPRINT_LIST_URL).get_json_response
sprints = sprints_json['values'].map { |sprint_json| Sprint.new(sprint_json) }

puts "==> Choose an active or future sprint:"

sprints.each do |sprint|
  puts "   ID: #{sprint.id}; State: #{sprint.state}; Name: #{sprint.name}"
end

puts ''

puts "   Enter an ID:"

SPRINT_ID = gets.strip

abort('Unknown sprint!') unless sprints.map{ |sprint| sprint.id }.include?(SPRINT_ID.to_i)

SPRINT_ISSUES_URL = "https://#{JIRA_DOMAIN}/rest/agile/1.0/board/#{BOARD_ID}/sprint/#{SPRINT_ID}/issue"

issues_json = HttpRequester.new(SPRINT_ISSUES_URL).get_paginated_json_response('issues')
issues = issues_json['values'].map { |issue_json| Issue.new(issue_json) }

subtasks = issues.select { |issue| issue.subtask? || !issue.has_subtasks? }.compact

subtasks_grouped_by_assignee = subtasks.group_by { |subtask| subtask.assignee_name }

time_in_sprint_per_person = subtasks_grouped_by_assignee.reduce([]) do |array, (assignee, subtasks)|
  hours_in_sprint = subtasks.reduce(0) { |sum, subtask| sum += subtask.original_estimate_hours }
  array << [assignee, hours_in_sprint]
  array
end

table = Terminal::Table.new
table.title = 'Hours per person in sprint'
table.headings = ['Person', 'Hours']
table.rows = time_in_sprint_per_person
table.align_column(1, :right)

puts table

if subtasks_grouped_by_assignee['Unknown'].count > 0
  unassigned_subtasks_keys = subtasks_grouped_by_assignee['Unknown'].map { |subtask| [subtask.key, subtask.original_estimate_hours] }

  table = Terminal::Table.new
  table.title = 'List of unassigned subtasks'
  table.headings = ['Task key', 'Estimate']
  table.rows = unassigned_subtasks_keys
  table.style = {width: 40}

  puts ''
  
  puts table
end
