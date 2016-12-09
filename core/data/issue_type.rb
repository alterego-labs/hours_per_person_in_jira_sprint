class IssueType
  include Virtus.model

  attribute :subtask, Axiom::Types::Boolean, default: false

  def subtask?
    subtask == true
  end
end

