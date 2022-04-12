defmodule SudoxuPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  def row, do: integer(0..8)
  def column, do: integer(0..8)
  def cell, do: tuple({row(), column()})
  def cell_value, do: integer(1..9)

  property "can put and get a value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put(cell, val)
      assert Sudoxu.get(board, cell) == val
    end
  end

  property "can put and get multiple values" do
    check all cell1 <- cell(),
              cell2 <- cell(),
              cell1 != cell2,
              val1 <- cell_value(),
              val2 <- cell_value(),
              val1 != val2 do
      board = Sudoxu.new() |> Sudoxu.put(cell1, val1) |> Sudoxu.put(cell2, val2)
      assert Sudoxu.get(board, cell1) == val1
      assert Sudoxu.get(board, cell2) == val2
    end
  end

  property "can put and get a hint" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put_hint(cell, val)
      assert Sudoxu.get(board, cell) == val
    end
  end

  property "can put and get multiple hints" do
    check all cell1 <- cell(),
              cell2 <- cell(),
              cell1 != cell2,
              val1 <- cell_value(),
              val2 <- cell_value(),
              val1 != val2 do
      board = Sudoxu.new() |> Sudoxu.put_hint(cell1, val1) |> Sudoxu.put_hint(cell2, val2)
      assert Sudoxu.get(board, cell1) == val1
      assert Sudoxu.get(board, cell2) == val2
    end
  end

  property "value placed by put is never a hint" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put(cell, val)
      refute Sudoxu.is_hint?(board, cell)
    end
  end

  property "value placed by put_hint is always a hint" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put_hint(cell, val)
      assert Sudoxu.is_hint?(board, cell)
    end
  end

  property "can delete a value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put(cell, val) |> Sudoxu.delete(cell)
      assert Sudoxu.empty?(board, cell)
      assert is_nil(Sudoxu.get(board, cell))
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
        Sudoxu.new()
        |> Sudoxu.put(cell1, val1)
        |> Sudoxu.put(cell2, val2)
        |> Sudoxu.delete(cell1)

      assert Sudoxu.get(board, cell2) == val2
    end
  end

  property "filled? always returns true for a solved value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put(cell, val)
      assert Sudoxu.filled?(board, cell)
    end
  end

  property "filled? always returns true for a hint value" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put_hint(cell, val)
      assert Sudoxu.filled?(board, cell)
    end
  end

  property "filled? always returns false on an empty board" do
    check all cell <- cell() do
      board = Sudoxu.new()
      refute Sudoxu.filled?(board, cell)
    end
  end

  property "empty? always returns true for an empty board" do
    check all cell <- cell() do
      board = Sudoxu.new()
      assert Sudoxu.empty?(board, cell)
    end
  end

  property "empty? always returns false on a solved cell" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put(cell, val)
      refute Sudoxu.empty?(board, cell)
    end
  end

  property "empty? always returns false on a hint cell" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put_hint(cell, val)
      refute Sudoxu.empty?(board, cell)
    end
  end

  property "get_row returns entire row" do
    check all row <- row(),
              col <- column(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put({col, row}, val)
      assert Enum.find_index(Sudoxu.get_row(board, row), &(&1 == val)) == col
    end
  end

  property "can_put? is always true for an empty cell" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new()
      assert Sudoxu.can_put?(board, cell, val)
    end
  end

  property "can_put? is always true when placing value on top of another" do
    check all cell <- cell(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put(cell, val)
      assert Sudoxu.can_put?(board, cell, val)
    end
  end

  property "cannot put a value in the same row twice" do
    check all row <- row(),
              col1 <- column(),
              col2 <- column(),
              col1 != col2,
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put({col1, row}, val)
      refute Sudoxu.can_put?(board, {col2, row}, val)
    end
  end

  property "cannot put a value in the same column twice" do
    check all row1 <- row(),
              row2 <- row(),
              row1 != row2,
              col <- column(),
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put({col, row1}, val)
      refute Sudoxu.can_put?(board, {col, row2}, val)
    end
  end

  property "cannot put a value in the same subgrid twice" do
    check all row1 <- integer(0..2),
              row2 <- integer(0..2),
              row1 != row2,
              col1 <- integer(0..2),
              col2 <- integer(0..2),
              col1 != col2,
              val <- cell_value() do
      board = Sudoxu.new() |> Sudoxu.put({col1, row1}, val)
      refute Sudoxu.can_put?(board, {col2, row2}, val)
    end
  end
end
