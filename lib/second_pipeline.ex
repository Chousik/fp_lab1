defmodule Spiral.Pipeline do
  @moduledoc """
  Pipeline-style calculation of the diagonal sum for an n×n number spiral.
  """

  def sum_diagonals(1), do: 1

  def sum_diagonals(n) do
    1..div(n - 1, 2)
    |> Enum.map(&layer_sum/1)
    |> Enum.reduce(1, &+/2)
  end

  defp layer_sum(k), do: 16 * k * k + 4 * k + 4
end
