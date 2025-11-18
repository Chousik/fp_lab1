defmodule First.StreamSolution do
  @moduledoc """
  Stream-based approach to computing the largest prime factor of a number.
  """

  def largest_prime_factor(n) do
    Stream.iterate(2, &(&1 + 1))
    |> Stream.take_while(fn d -> d * d <= n end)
    |> Stream.flat_map(fn x -> [x, div(n, x)] end)
    |> Stream.filter(&(rem(n, &1) == 0))
    |> Stream.filter(&prime?/1)
    |> Enum.max()
  end

  defp prime?(n) do
    cond do
      n <= 2 -> true
      rem(n, 2) == 0 -> false
      true -> check_div(n, 3)
    end
  end

  defp check_div(n, d) do
    cond do
      d * d > n -> true
      rem(n, d) == 0 -> false
      true -> check_div(n, d + 2)
    end
  end
end
