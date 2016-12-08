require "net/https"
require "uri"
require 'json'

require 'pry-nav'
require 'rb-readline'
require 'terminal-table'

USER_LOGIN = ENV['JIRA_USER_LOGIN']
USER_PASSWORD = ENV['JIRA_USER_PASSWORD']
JIRA_DOMAIN = ENV['JIRA_DOMAIN']

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
boards = boards_json['values']

puts "==> Choose a board:"

boards.each do |board|
  puts "   ID: #{board['id']}; Name: #{board['name']}"
end

puts ''

puts "   Enter an ID:"

BOARD_ID = gets.strip

abort('Unknown board!') unless boards.map{ |board| board['id'] }.include?(BOARD_ID.to_i)

puts ''

SPRINT_LIST_URL = "https://#{JIRA_DOMAIN}/rest/agile/1.0/board/#{BOARD_ID}/sprint?state=active,future"

sprints_json = HttpRequester.new(SPRINT_LIST_URL).get_json_response
sprints = sprints_json['values']

puts "==> Choose an active or future sprint:"

sprints.each do |sprint|
  puts "   ID: #{sprint['id']}; State: #{sprint['state']}; Name: #{sprint['name']}"
end

puts ''

puts "   Enter an ID:"

SPRINT_ID = gets.strip

abort('Unknown sprint!') unless sprints.map{ |sprint| sprint['id'] }.include?(SPRINT_ID.to_i)

SPRINT_ISSUES_URL = "https://#{JIRA_DOMAIN}/rest/agile/1.0/board/#{BOARD_ID}/sprint/#{SPRINT_ID}/issue"

issues_json = HttpRequester.new(SPRINT_ISSUES_URL).get_paginated_json_response('issues')
issues = issues_json['values']

subtasks = issues.select do |issue|
  (issue['fields']['issuetype']['subtask'] == true) || (issue['fields']['subtasks'].empty?)
end.compact

subtasks_grouped_by_assignee = subtasks.group_by do |subtask|
  begin
    subtask
      .fetch('fields', {})
      .fetch('assignee', {})
      .fetch('name', 'Unknown')
  rescue
    'Unknown'
  end
end

time_in_sprint_per_person = subtasks_grouped_by_assignee.reduce({}) do |hash, (assignee, subtasks)|
  hours_in_sprint = subtasks.reduce(0) { |sum, subtask| sum += subtask['fields']['timeoriginalestimate'].to_i }
  hash[assignee] = hours_in_sprint / 3600.0
  hash
end

table = Terminal::Table.new
table.title = 'Hours per person in sprint'
table.headings = ['Person', 'Hours']
table.rows = Array(time_in_sprint_per_person)
table.align_column(1, :right)

puts table

if subtasks_grouped_by_assignee['Unknown'].count > 0
  unassigned_subtasks_keys = subtasks_grouped_by_assignee['Unknown'].map { |subtask| [subtask['key'], subtask['fields']['timeoriginalestimate'].to_i / 3600.0] }

  table = Terminal::Table.new
  table.title = 'List of unassigned subtasks'
  table.headings = ['Task key', 'Estimate']
  table.rows = unassigned_subtasks_keys
  table.style = {width: 40}

  puts ''
  
  puts table
end
