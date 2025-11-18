defmodule First.Tail do
  @moduledoc """
  Tail-recursive approach to finding the largest prime factor of a number.
  """

  def largest_prime_factor(n), do: do_lpf_tail(n, 2, 1)

  defp do_lpf_tail(n, factor, current_max) when factor * factor > n do
    max(current_max, n)
  end

  defp do_lpf_tail(n, factor, current_max) do
    if rem(n, factor) == 0 do
      do_lpf_tail(div(n, factor), factor, factor)
    else
      do_lpf_tail(n, factor + 1, current_max)
    end
  end
end
