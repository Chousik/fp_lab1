defmodule Spiral.Tail do
  @moduledoc """
  Tail-recursive diagonal sum for an n×n number spiral.
  """

  def sum_diagonals(1), do: 1

  def sum_diagonals(n) do
    layers = div(n - 1, 2)
    do_sum(1, layers, 1)
  end

  defp do_sum(k, layers, acc) when k > layers, do: acc

  defp do_sum(k, layers, acc) do
    do_sum(k + 1, layers, acc + layer_sum(k))
  end

  defp layer_sum(k), do: 16 * k * k + 4 * k + 4
end
