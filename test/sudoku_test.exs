defmodule SudokuTest do
  use ExUnit.Case, async: true
  doctest Sudoku

  test "{0, 0} is the first element of the squares list" do
    board = Sudoku.new() |> Sudoku.put({0, 0}, 1)

    assert List.first(board.squares) == 1
  end

  test "{0, 1} is the tenth element of the squares list" do
    board = Sudoku.new() |> Sudoku.put({0, 1}, 1)

    assert Enum.at(board.squares, 9) == 1
  end

  test "{1, 0} is the second element of the squares list" do
    board = Sudoku.new() |> Sudoku.put({1, 0}, 1)

    assert Enum.at(board.squares, 1) == 1
  end

  test "{8, 8} is the 81st element of the squares list" do
    board = Sudoku.new() |> Sudoku.put({8, 8}, 1)

    assert Enum.at(board.squares, 80) == 1
  end

  test "get_row" do
    row = Sudoku.new() |> Sudoku.put({0, 8}, 1) |> Sudoku.get_row(8)

    assert row == [1, nil, nil, nil, nil, nil, nil, nil, nil]
  end

  test "get_column" do
    column = Sudoku.new() |> Sudoku.put({8, 0}, 1) |> Sudoku.get_column(8)

    assert column == [1, nil, nil, nil, nil, nil, nil, nil, nil]
  end

  test "can_put? regression" do
    board = Sudoku.new() |> Sudoku.put({8, 3}, 1)

    refute Sudoku.can_put?(board, {1, 3}, 1)
  end

  test "can_put? regression 2" do
    board = Sudoku.new() |> Sudoku.put({8, 2}, 1)

    refute Sudoku.can_put?(board, {1, 2}, 1)
  end

  test "subgrid at edges" do
    board =
      Sudoku.new()
      |> Sudoku.put({8, 8}, 9)

    assert Sudoku.get_subgrid_of(board, {8, 8}) == [nil, nil, nil, nil, nil, nil, nil, nil, 9]
  end

  test "put/3 raises when you try to put the same value in a subgrid twice" do
    board =
      Sudoku.new()
      |> Sudoku.put({8, 8}, 9)

    assert_raise RuntimeError, fn ->
      Sudoku.put(board, {7, 7}, 9)
    end
  end
end
