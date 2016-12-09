class IssueAssignee
  include Virtus.model

  attribute :name, String, default: 'Unknown'
end
