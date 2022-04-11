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

  defstruct squares: @empty_board,
            hints: @empty_board

  @type t :: %__MODULE__{
    squares: nonempty_list(cell_value()),
    hints: nonempty_list(cell_value())
  }

  @type row() :: 0..8
  @type column() :: 0..8
  @type cell() :: {column(), row()}
  @type cell_value() :: nil | 1..9

  defguardp is_row(row) when row in 0..8
  defguardp is_column(col) when col in 0..8
  defguardp is_cell(cell) when is_column(elem(cell, 0)) and is_row(elem(cell, 1))
  defguardp is_cell_value(x) when is_integer(x) and x in 1..9

  @doc """
  Create a new, empty Sudoku board.

      iex> Sudoku.new()
      ...> |> Sudoku.empty?({0, 0})
      true
  """
  @spec new() :: t()
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
  @spec put(t(), cell(), cell_value()) :: t()
  def put(%Sudoku{squares: squares} = sudoku, cell, val)
      when is_cell(cell) and is_cell_value(val) do
    if is_hint?(sudoku, cell) do
      raise "Cannot insert a value over a hint"
    end

    unless can_put?(sudoku, cell, val) do
      raise "Cannot insert a value that is already present in the current row, column, and subgrid"
    end

    %Sudoku{sudoku | squares: List.replace_at(squares, cell_index(cell), val)}
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
      ...> |> Sudoku.put({0, 0}, 1)
      ...> |> Sudoku.can_put?({1, 0}, 1)
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
  @spec can_put?(t(), cell(), cell_value()) :: boolean()
  def can_put?(%Sudoku{} = sudoku, cell = {col, row}, val)
      when is_cell(cell) and is_cell_value(val) do
    if is_hint?(sudoku, cell) do
      false
    else
      # Clear the cell so that it isn't included in the row, column, and subgrid sets.
      # This way we can check if we can replace a value with another value.
      sudoku_with_space = delete(sudoku, cell)

      row_values = get_row(sudoku_with_space, row)
      column_values = get_column(sudoku_with_space, col)
      subgrid_values = get_subgrid_of(sudoku_with_space, cell)

      val not in row_values and val not in column_values and val not in subgrid_values
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
  @spec get(t(), cell()) :: cell_value()
  def get(%Sudoku{squares: squares, hints: hints}, cell) when is_cell(cell) do
    index = cell_index(cell)

    if hint_val = Enum.at(hints, index) do
      hint_val
    else
      Enum.at(squares, index)
    end
  end

  @doc """
  Returns all values in the given row. Empty cells are returned as `nil`.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.get_row(2)
      [nil, 1, nil, nil, nil, nil, nil, nil, nil]
  """
  @spec get_row(t(), row()) :: nonempty_list(cell_value())
  def get_row(sudoku, row) when is_row(row) do
    for i <- 0..8, do: get(sudoku, {i, row})
  end

  @doc """
  Returns all values in the given column. Empty cells are returned as `nil`.

      iex> Sudoku.new()
      ...> |> Sudoku.put({1, 2}, 1)
      ...> |> Sudoku.get_column(1)
      [nil, nil, 1, nil, nil, nil, nil, nil, nil]
  """
  @spec get_column(t(), column()) :: nonempty_list(cell_value())
  def get_column(sudoku, column) when is_column(column) do
    for i <- 0..8, do: get(sudoku, {column, i})
  end

  @doc """
  Gets the three-by-three subgrid containing the given cell. Empty cells are returned as `nil`.

      iex> Sudoku.new()
      ...> |> Sudoku.put({0, 0}, 1)
      ...> |> Sudoku.get_subgrid_of({1, 1})
      [1, nil, nil, nil, nil, nil, nil, nil, nil]
  """
  @spec get_subgrid_of(t(), cell()) :: nonempty_list(cell_value())
  def get_subgrid_of(sudoku, {col, row} = cell) when is_cell(cell) do
    subgrid_start_col = col - rem(col, 3)
    subgrid_start_row = row - rem(row, 3)

    for subgrid_col <- subgrid_start_col..(subgrid_start_col + 2),
        subgrid_row <- subgrid_start_row..(subgrid_start_row + 2) do
      get(sudoku, {subgrid_col, subgrid_row})
    end
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
  @spec delete(t(), cell()) :: t()
  def delete(%Sudoku{squares: squares} = sudoku, cell) when is_cell(cell) do
    if is_hint?(sudoku, cell) do
      raise "Cannot delete a hint this way. Use `delete_hint/2`"
    end

    %Sudoku{sudoku | squares: List.replace_at(squares, cell_index(cell), nil)}
  end

  @doc """
  Put a hint into the board. The cell will be overwritten.

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
  @spec put_hint(t(), cell(), cell_value()) :: t()
  def put_hint(%Sudoku{squares: squares, hints: hints} = sudoku, cell, val)
      when is_cell(cell) and is_cell_value(val) do
    %Sudoku{sudoku
      | squares: List.replace_at(squares, cell_index(cell), nil),
        hints: List.replace_at(hints, cell_index(cell), val)}
  end

  @doc """
  Delete a hint from the board.
  """
  @spec delete_hint(t(), cell()) :: t()
  def delete_hint(%Sudoku{squares: squares, hints: hints} = sudoku, cell) when is_cell(cell) do
    %Sudoku{
      sudoku
      | squares: List.replace_at(squares, cell_index(cell), nil),
        hints: List.replace_at(hints, cell_index(cell), nil)
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
  @spec is_hint?(t(), cell()) :: boolean()
  def is_hint?(%Sudoku{hints: hints}, cell) when is_cell(cell) do
    not is_nil(Enum.at(hints, cell_index(cell)))
  end

  defp cell_index({col, row}) do
    col + row * 9
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
  @spec filled?(t(), cell()) :: boolean()
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
  @spec empty?(t(), cell()) :: boolean()
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
  @spec solved_count(t()) :: non_neg_integer()
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
  @spec hint_count(t()) :: non_neg_integer()
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
  @spec filled_count(t()) :: non_neg_integer()
  def filled_count(%Sudoku{} = sudoku) do
    Sudoku.solved_count(sudoku) + Sudoku.hint_count(sudoku)
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(sudoku, opts) do
      hint_count = Enum.count(sudoku.hints, fn x -> not is_nil(x) end)
      normal_count = Enum.count(sudoku.squares, fn x -> not is_nil(x) end)

      completed? = hint_count + normal_count == 81

      stats = %{
        completed: completed?,
        filled: normal_count,
        hints: hint_count
      }

      concat(["#Sudoku<", to_doc(stats, opts), ">"])
    end
  end
end
