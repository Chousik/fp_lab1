defmodule Fplab1.StreamProcessor do
  @moduledoc """
  Coordinates streaming input with interpolation algorithms.
  """

  alias Fplab1.Input
  alias Fplab1.Interpolation.Algorithm

  @type algorithm_config :: {module(), keyword()}

  @spec run(Enumerable.t(), keyword()) :: :ok | {:error, String.t()}
  def run(lines, opts) do
    algorithms = build_algorithms(Keyword.fetch!(opts, :algorithms))
    emit = Keyword.fetch!(opts, :emit)

    initial_state = %{algorithms: algorithms, emit: emit, last_x: nil}

    result =
      lines
      |> Stream.with_index(1)
      |> Enum.reduce_while({:ok, initial_state}, fn {line, line_no}, {:ok, state} ->
        process_line(line, line_no, state)
      end)

    with {:ok, state} <- result do
      finalize(state)
    end
  end

  defp build_algorithms(configs) do
    Enum.map(configs, fn {module, args} -> {module, module.init(args)} end)
  end

  defp process_line(line, line_no, state) do
    case Input.parse_line(line) do
      :skip ->
        {:cont, {:ok, state}}

      {:error, reason} ->
        {:halt, {:error, "Line #{line_no}: #{reason}"}}

      {:ok, {x, _} = point} ->
        handle_point(state, point, line_no, x)
    end
  end

  defp handle_point(state, point, line_no, x) do
    if valid_order?(state.last_x, x) do
      case dispatch_point(state, point) do
        {:ok, new_state} -> {:cont, {:ok, new_state}}
        {:error, message} -> {:halt, {:error, "Line #{line_no}: #{message}"}}
      end
    else
      {:halt, {:error, "Line #{line_no}: x must be strictly increasing"}}
    end
  end

  defp dispatch_point(state, point) do
    {entries, updated_algorithms} =
      Enum.map_reduce(state.algorithms, [], fn {module, alg_state}, acc ->
        {new_state, outputs} = module.consume(alg_state, point)
        {{module.label(new_state), outputs}, [{module, new_state} | acc]}
      end)

    Enum.each(entries, fn {label, outputs} ->
      Enum.each(outputs, fn {x, y} -> state.emit.(label, x, y) end)
    end)

    {:ok, %{state | algorithms: Enum.reverse(updated_algorithms), last_x: elem(point, 0)}}
  end

  defp finalize(state) do
    Enum.each(state.algorithms, fn {module, alg_state} ->
      {new_state, outputs} = module.finalize(alg_state)
      label = module.label(new_state)
      Enum.each(outputs, fn {x, y} -> state.emit.(label, x, y) end)
    end)
  end

  defp valid_order?(nil, _), do: true
  defp valid_order?(prev, current), do: current > prev
end
