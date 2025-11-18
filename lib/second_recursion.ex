defmodule Spiral.Recursion do
  @moduledoc """
  Recursive implementation for summing diagonals in an n×n number spiral.
  """

  def sum_diagonals(1), do: 1

  def sum_diagonals(n) when n > 1 and rem(n, 2) == 1 do
    layers = div(n - 1, 2)
    1 + do_sum(1, layers)
  end

  defp do_sum(k, layers) when k > layers, do: 0

  defp do_sum(k, layers) do
    layer_sum(k) + do_sum(k + 1, layers)
  end

  defp layer_sum(k), do: 16 * k * k + 4 * k + 4
end
