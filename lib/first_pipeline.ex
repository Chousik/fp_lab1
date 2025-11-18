defmodule First.Pipeline do
  @moduledoc """
  Pipeline-based solution for finding the largest prime factor of a number.
  """

  def largest_prime_factor(n) do
    2..sqrt_int(n)
    |> Enum.filter(&(rem(n, &1) == 0))
    |> Enum.flat_map(fn x -> [x, div(n, x)] end)
    |> Enum.filter(&prime?/1)
    |> Enum.max()
  end

  defp sqrt_int(n) do
    n
    |> :math.sqrt()
    |> trunc()
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
