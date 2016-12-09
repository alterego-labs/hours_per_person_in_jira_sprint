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
    (fields.assignee || IssueAssignee.new).name
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

