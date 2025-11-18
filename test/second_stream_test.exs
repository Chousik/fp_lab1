defmodule Spiral.StreamTest do
  use ExUnit.Case

  @cases [
    {1, 1},
    {3, 25},
    {5, 101},
    {7, 261},
    {9, 537},
    {11, 961},
    {101, 692_101}
  ]

  describe "Spiral.StreamSolution" do
    for {input, expected} <- @cases do
      test "sum_diagonals(#{input}) == #{expected}" do
        assert Spiral.StreamSolution.sum_diagonals(unquote(input)) == unquote(expected)
      end
    end
  end
end
