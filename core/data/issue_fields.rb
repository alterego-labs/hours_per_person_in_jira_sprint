class IssueFields
  include Virtus.model

  attribute :subtasks
  attribute :assignee, IssueAssignee
  attribute :issuetype, IssueType
  attribute :timetracking, IssueTimeTracking
end

