defmodule Spiral.TailTest do
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

  describe "Spiral.Tail" do
    for {input, expected} <- @cases do
      test "sum_diagonals(#{input}) == #{expected}" do
        assert Spiral.Tail.sum_diagonals(unquote(input)) == unquote(expected)
      end
    end
  end
end
