module CLI
  class Options < Struct.new(:board, :sprint)
    def board_set?
      board != nil && board != ""
    end

    def sprint_set?
      sprint != nil && sprint != ""
    end
  end
end
