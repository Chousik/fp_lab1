defmodule First.Recursion do
  @moduledoc """
  Recursive implementation that finds a number's largest prime factor.
  """

  def largest_prime_factor(n), do: do_lpf_rec(n, 2)

  defp do_lpf_rec(n, factor) when factor * factor > n, do: n

  defp do_lpf_rec(n, factor) do
    if rem(n, factor) == 0 do
      max(factor, do_lpf_rec(div(n, factor), factor))
    else
      do_lpf_rec(n, factor + 1)
    end
  end
end
