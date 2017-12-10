require_relative 'board'

BOARDS = [
  {
    id: 1,
    path: "/dev",
    description: "development board"
  }
].freeze

class BoardRepository
  def find(id)
    attrs = BOARDS.find { |b| b[:id] == id }
    return nil if attrs.nil? # TODO: Return NullObject instead?
    Board.new(attrs)
  end

  def find_by_name(name)
    attrs = BOARDS.find { |b| b[:path] == "/#{name}" }
    return nil if attrs.nil? # TODO: Return NullObject instead?
    Board.new(attrs)
  end
end
