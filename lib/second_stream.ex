defmodule Spiral.StreamSolution do
  @moduledoc """
  Stream-based approach for summing diagonals of an n×n number spiral.
  """

  def sum_diagonals(1), do: 1

  def sum_diagonals(n) do
    layers = div(n - 1, 2)

    Stream.iterate(1, &(&1 + 1))
    |> Stream.take_while(&(&1 <= layers))
    |> Stream.map(&layer_sum/1)
    |> Enum.reduce(1, &+/2)
  end

  defp layer_sum(k), do: 16 * k * k + 4 * k + 4
end
