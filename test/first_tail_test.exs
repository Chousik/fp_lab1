defmodule First.TailTest do
  use ExUnit.Case

  @cases [
    {4, 2},
    {6, 3},
    {8, 2},
    {9, 3},
    {10, 5},
    {12, 3},
    {14, 7},
    {18, 3},
    {21, 7}
  ]

  describe "First.Tail" do
    for {input, expected} <- @cases do
      test "largest_prime_factor(#{input}) == #{expected}" do
        assert First.Tail.largest_prime_factor(unquote(input)) == unquote(expected)
      end
    end
  end
end
