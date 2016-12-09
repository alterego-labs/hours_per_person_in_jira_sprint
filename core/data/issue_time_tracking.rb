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

