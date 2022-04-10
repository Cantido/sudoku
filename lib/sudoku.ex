defmodule Sudoku do
  @moduledoc """
  A Sudoku board.

  A Sudoku is a nine-by-nine set of cells, each cell can contain an integer with a value of one through nine.
  Coordinates of cells are zero-indexed.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.get({1, 2})
      1

  Calling `get/2` for an empty cell will return `nil`.

      iex> Sudoku.new()
      ...> |> Sudoku.get({3, 4})
      nil

  Inserting a value that breaks the Sudoku rules will raise an error.
  Use `can_put/3` to check before inserting a value.

      iex> Sudoku.new()
      ...> |> Sudoku.put({0, 0}, 5)
      ...> |> Sudoku.put({1, 1}, 5)
      ** (RuntimeError) Cannot insert a value that is already present in the current row, column, and subgrid

  There are a few predicate functions to make it easier to interact with the board:

      iex> board = Sudoku.new()
      ...> |> Sudoku.put({2, 8}, 7)
      iex> Sudoku.filled?(board, {2, 8})
      true
      iex> Sudoku.filled?(board, {3, 8})
      false

      iex> board = Sudoku.new()
      ...> |> Sudoku.put({4, 5}, 3)
      iex> Sudoku.empty?(board, {4, 5})
      false
      iex> Sudoku.empty?(board, {5, 6})
      true

  To prepare puzzles, you can place hints into the board.
  Hints are special cells that cannot be overridden with `put/3`, and will raise an error if you try to do so.
  You can put a hint into the board with `put_hint/3`, and remove it with `delete_hint/2`.

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({1, 2}, 1)
      ...> |> Sudoku.put({1, 2}, 3)
      ** (RuntimeError) Cannot insert a value over a hint

  You can check if a cell contains a hint with `is_hint?/2`

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({1, 2}, 1)
      ...> |> Sudoku.is_hint?({1, 2})
      true
  """

  @empty_board Stream.cycle([nil]) |> Enum.take(81)

  defstruct [
    squares: @empty_board,
    hints: @empty_board
  ]

  defguardp is_cell(cell) when elem(cell, 0) in 0..8 and elem(cell, 1) in 0..8
  defguardp is_cell_value(x) when is_integer(x) and x in 1..9

  @doc """
  Create a new, empty Sudoku board.

      iex> Sudoku.new()
      ...> |> Sudoku.empty?({0, 0})
      true
  """
  def new do
    %Sudoku{}
  end


  @doc """
  Put a value into a cell. Normal cell values are replaced, but this function will raise an error if you try to put a value over a hint.
  Use `is_hint?/2` to check if a cell contains a hint first.
  This function will raise if you try to put a value that breaks the Sudoku rules.
  Use `can_put?/3` to check if you are allowed to put a value in a cell.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.get({1, 2})
      1

      iex> Sudoku.new()
      ...> |> Sudoku.put({3, 7}, 5)
      ...> |> Sudoku.put({3, 7}, 9)
      ...> |> Sudoku.get({3, 7})
      9

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({3, 7}, 5)
      ...> |> Sudoku.put({3, 7}, 9)
      ** (RuntimeError) Cannot insert a value over a hint

      iex> Sudoku.new()
      ...> |> Sudoku.put({0, 0}, 5)
      ...> |> Sudoku.put({1, 1}, 5)
      ** (RuntimeError) Cannot insert a value that is already present in the current row, column, and subgrid

  """
  def put(%Sudoku{squares: squares} = sudoku, cell, val) when is_cell(cell) and is_cell_value(val) do
    if is_hint?(sudoku, cell) do
      raise "Cannot insert a value over a hint"
    end
    unless can_put?(sudoku, cell, val) do
      raise "Cannot insert a value that is already present in the current row, column, and subgrid"
    end

    %Sudoku{sudoku | squares: List.insert_at(squares, cell_index(cell), val)}
  end

  @doc """
  Checks if you can place a number in the given cell.
  You can put a value over another value, but you cannot put a value over a hint.


      iex> Sudoku.new()
      ...> |> Sudoku.can_put?({0, 0}, 1)
      true

      iex> Sudoku.new()
      ...> |> Sudoku.put({0, 0}, 9)
      ...> |> Sudoku.can_put?({0, 0}, 1)
      true

      iex> Sudoku.new()
      ...> |> Sudoku.put({0, 0}, 1)
      ...> |> Sudoku.can_put?({0, 1}, 1)
      false

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({0, 0}, 9)
      ...> |> Sudoku.can_put?({0, 0}, 1)
      false

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({0, 0}, 1)
      ...> |> Sudoku.can_put?({1, 1}, 1)
      false
  """
  def can_put?(%Sudoku{} = sudoku, cell = {col, row}, val) when is_cell(cell) and is_cell_value(val) do
    if is_hint?(sudoku, cell) do
      false
    else
      # Clear the cell so that it isn't included in the row, column, and subgrid sets.
      # This way we can check if we can replace a value with another value.
      sudoku = delete(sudoku, cell)

      row_values = for i <- 0..8, do: get(sudoku, {col, i})
      column_values = for i <- 0..8, do: get(sudoku, {i, row})

      subgrid_start_col = div(col, 3)
      subgrid_start_row = div(row, 3)

      subgrid_values =
        for subgrid_col <- subgrid_start_col..(subgrid_start_col + 2),
            subgrid_row <- subgrid_start_row..(subgrid_start_row + 2) do
            get(sudoku, {subgrid_col, subgrid_row})
        end

      (val not in row_values) and (val not in column_values) and (val not in subgrid_values)
    end
  end

  @doc """
  Get a cell's value.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.get({1, 2})
      1

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({3, 7}, 9)
      ...> |> Sudoku.get({3, 7})
      9
  """
  def get(%Sudoku{squares: squares, hints: hints}, cell) when is_cell(cell) do
    Enum.at(hints, cell_index(cell)) || Enum.at(squares, cell_index(cell))
  end

  @doc """
  Delete a cell's value. This function will raise if you try to delete a hint. Use `delete_hint/2` to delete a hint instead.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.delete({1, 2})
      ...> |> Sudoku.empty?({1, 2})
      true


      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({3, 7}, 9)
      ...> |> Sudoku.delete({3, 7})
      ** (RuntimeError) Cannot delete a hint this way. Use `delete_hint/2`
  """
  def delete(%Sudoku{squares: squares} = sudoku, cell) when is_cell(cell) do
    if is_hint?(sudoku, cell) do
      raise "Cannot delete a hint this way. Use `delete_hint/2`"
    end

    %Sudoku{sudoku | squares: List.insert_at(squares, cell_index(cell), nil)}
  end

  @doc """
  Put a hint into the board. Existing hints will be overridden.

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({1, 2}, 1)
      ...> |> Sudoku.get({1, 2})
      1

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({3, 7}, 5)
      ...> |> Sudoku.put_hint({3, 7}, 9)
      ...> |> Sudoku.get({3, 7})
      9
  """
  def put_hint(%Sudoku{hints: hints} = sudoku, cell, val) when is_cell(cell) and is_cell_value(val) do
    %Sudoku{sudoku | hints: List.insert_at(hints, cell_index(cell), val)}
  end

  @doc """
  Delete a hint from the board.
  """
  def delete_hint(%Sudoku{squares: squares, hints: hints} = sudoku, cell) when is_cell(cell) do
    %Sudoku{sudoku |
      squares: List.insert_at(squares, cell_index(cell), nil),
      hints: List.insert_at(hints, cell_index(cell), nil)
    }
  end

  @doc """
  Check if a cell contains a hint.

      iex> Sudoku.new()
      ...> |> Sudoku.put_hint({1, 2}, 1)
      ...> |> Sudoku.is_hint?({1, 2})
      true

      iex> Sudoku.new()
      ...> |> Sudoku.is_hint?({1, 2})
      false
  """
  def is_hint?(%Sudoku{hints: hints}, cell) when is_cell(cell) do
    not is_nil(Enum.at(hints, cell_index(cell)))
  end

  defp cell_index({x, y}) do
    x + (y * 9)
  end

  @doc """
  Returns true if the cell contains a value.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.filled?({1, 2})
      true

      iex> Sudoku.new()
      ...> |> Sudoku.filled?({1, 2})
      false
  """
  def filled?(%Sudoku{} = sudoku, cell) when is_cell(cell) do
    not empty?(sudoku, cell)
  end

  @doc """
  Returns true if the cell does not contain a value.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.empty?({1, 2})
      false

      iex> Sudoku.new()
      ...> |> Sudoku.empty?({1, 2})
      true
  """
  def empty?(%Sudoku{} = sudoku, cell) when is_cell(cell) do
    is_nil(get(sudoku, cell))
  end

  @doc """
  Returns the count of filled non-hint squares.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.put({6, 7}, 2)
      ...> |> Sudoku.put_hint({3, 4}, 5)
      ...> |> Sudoku.solved_count()
      2

      iex> Sudoku.new()
      ...> |> Sudoku.solved_count()
      0
  """
  def solved_count(%Sudoku{squares: squares}) do
    Enum.count(squares, fn x -> not is_nil(x) end)
  end

  @doc """
  Returns the count of hint squares.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.put({6, 7}, 2)
      ...> |> Sudoku.put_hint({3, 4}, 5)
      ...> |> Sudoku.hint_count()
      1

      iex> Sudoku.new()
      ...> |> Sudoku.hint_count()
      0
  """
  def hint_count(%Sudoku{hints: hints}) do
    Enum.count(hints, fn x -> not is_nil(x) end)
  end

  @doc """
  Returns the count of cells containing a number, including both hints and solved cells.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.put({6, 7}, 2)
      ...> |> Sudoku.put_hint({3, 4}, 5)
      ...> |> Sudoku.filled_count()
      3

      iex> Sudoku.new()
      ...> |> Sudoku.filled_count()
      0
  """
  def filled_count(%Sudoku{} = sudoku) do
    Sudoku.solved_count(sudoku) + Sudoku.hint_count(sudoku)
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(sudoku, opts) do
      hint_count = Enum.count(sudoku.hints, fn x -> not is_nil(x) end)
      normal_count = Enum.count(sudoku.squares, fn x -> not is_nil(x) end)

      completed? = (hint_count + normal_count) == 81

      stats = %{
        completed: completed?,
        filled: normal_count,
        hints: hint_count
      }

      concat(["#Sudoku<", to_doc(stats, opts), ">"])
    end
  end
end
