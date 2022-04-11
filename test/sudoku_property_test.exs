defmodule SudokuPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  def row, do: integer(0..8)
  def column, do: integer(0..8)
  def cell, do: tuple({row(), column()})
  def cell_value, do: integer(1..9)

  property "can put and get a value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put(cell, val)
      assert Sudoku.get(board, cell) == val
    end
  end

  property "can put and get multiple values" do
    check all cell1 <- cell(),
              cell2 <- cell(),
              cell1 != cell2,
              val1 <- cell_value(),
              val2 <- cell_value(),
              val1 != val2 do
      board = Sudoku.new() |> Sudoku.put(cell1, val1) |> Sudoku.put(cell2, val2)
      assert Sudoku.get(board, cell1) == val1
      assert Sudoku.get(board, cell2) == val2
    end
  end

  property "can put and get a hint" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put_hint(cell, val)
      assert Sudoku.get(board, cell) == val
    end
  end

  property "can put and get multiple hints" do
    check all cell1 <- cell(),
              cell2 <- cell(),
              cell1 != cell2,
              val1 <- cell_value(),
              val2 <- cell_value(),
              val1 != val2 do
      board = Sudoku.new() |> Sudoku.put_hint(cell1, val1) |> Sudoku.put_hint(cell2, val2)
      assert Sudoku.get(board, cell1) == val1
      assert Sudoku.get(board, cell2) == val2
    end
  end

  property "value placed by put is never a hint" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put(cell, val)
      refute Sudoku.is_hint?(board, cell)
    end
  end

  property "value placed by put_hint is always a hint" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put_hint(cell, val)
      assert Sudoku.is_hint?(board, cell)
    end
  end

  property "can delete a value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put(cell, val) |> Sudoku.delete(cell)
      assert Sudoku.empty?(board, cell)
      assert is_nil(Sudoku.get(board, cell))
    end
  end

  property "can delete a value without shifting other values" do
    check all cell1 <- cell(),
              cell2 <- cell(),
              cell1 != cell2,
              val1 <- cell_value(),
              val2 <- cell_value(),
              val1 != val2 do
      board =
        Sudoku.new()
        |> Sudoku.put(cell1, val1)
        |> Sudoku.put(cell2, val2)
        |> Sudoku.delete(cell1)
      assert Sudoku.get(board, cell2) == val2
    end
  end

  property "filled? always returns true for a solved value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put(cell, val)
      assert Sudoku.filled?(board, cell)
    end
  end

  property "filled? always returns true for a hint value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put_hint(cell, val)
      assert Sudoku.filled?(board, cell)
    end
  end

  property "filled? always returns false on an empty board" do
    check all cell <- cell() do
      board = Sudoku.new()
      refute Sudoku.filled?(board, cell)
    end
  end

  property "empty? always returns true for an empty board" do
    check all cell <- cell() do
      board = Sudoku.new()
      assert Sudoku.empty?(board, cell)
    end
  end

  property "empty? always returns false on a solved cell" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put(cell, val)
      refute Sudoku.empty?(board, cell)
    end
  end

  property "empty? always returns false on a hint cell" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put_hint(cell, val)
      refute Sudoku.empty?(board, cell)
    end
  end

  property "get_row returns entire row" do
    check all row <- row(),
              col <- column(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put({col, row}, val)
      assert Enum.find_index(Sudoku.get_row(board, row), &(&1 == val)) == col
    end
  end

  property "can_put? is always true for an empty cell" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new()
      assert Sudoku.can_put?(board, cell, val)
    end
  end

  property "can_put? is always true when placing value on top of another" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put(cell, val)
      assert Sudoku.can_put?(board, cell, val)
    end
  end

  property "cannot put a value in the same row twice" do
    check all row <- row(),
              col1 <- column(),
              col2 <- column(),
              col1 != col2,
              val <- cell_value() do
      board = Sudoku.new() |> Sudoku.put({col1, row}, val)
      refute Sudoku.can_put?(board, {col2, row}, val)
    end
  end
end
