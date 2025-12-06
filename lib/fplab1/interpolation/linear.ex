defmodule Fplab1.Interpolation.Linear do
  @moduledoc """
  Piecewise linear interpolation using streaming input.
  """

  @behaviour Fplab1.Interpolation.Algorithm

  alias Fplab1.Sampler

  @enforce_keys [:label, :sampler]
  defstruct label: "linear", sampler: Sampler.new(1.0), points: [], epsilon: 1.0e-9

  @impl true
  def init(opts) do
    step = Keyword.fetch!(opts, :step)

    %__MODULE__{
      label: Keyword.get(opts, :label, "linear"),
      sampler: Sampler.new(step),
      points: [],
      epsilon: Keyword.get(opts, :epsilon, 1.0e-9)
    }
  end

  @impl true
  def consume(%__MODULE__{} = state, point) do
    points = state.points ++ [point]
    sampler = Sampler.prime(state.sampler, elem(point, 0))
    state = %{state | points: points, sampler: sampler}
    emit(state, [])
  end

  @impl true
  def finalize(%__MODULE__{} = state) do
    state = maybe_force_last(state)
    emit(state, [])
  end

  @impl true
  def label(%__MODULE__{label: label}), do: label

  defp emit(state, acc) do
    last_x = last_point_x(state.points)

    case Sampler.next_target(state.sampler, last_x) do
      {:ok, target} ->
        case evaluate(state.points, target, state.epsilon) do
          {:ok, value} ->
            sampler = Sampler.advance(state.sampler)
            emit(%{state | sampler: sampler}, [{target, value} | acc])

          :not_ready ->
            {state, Enum.reverse(acc)}
        end

      :not_ready ->
        {state, Enum.reverse(acc)}
    end
  end

  defp evaluate([], _target, _eps), do: :not_ready
  defp evaluate([point], target, eps), do: locate_exact(point, target, eps)
  defp evaluate(points, target, eps), do: locate(points, target, eps)

  defp locate([point], target, eps), do: locate_exact(point, target, eps)

  defp locate([current, next | rest], target, eps) do
    current_x = elem(current, 0)
    next_x = elem(next, 0)

    cond do
      abs(current_x - target) <= eps -> {:ok, elem(current, 1)}
      target < current_x - eps -> :not_ready
      target <= next_x + eps -> interpolate_or_exact(current, next, target, eps)
      true -> locate([next | rest], target, eps)
    end
  end

  defp locate([], _target, _eps), do: :not_ready

  defp interpolate_or_exact(_current, next, target, eps) when abs(elem(next, 0) - target) <= eps,
    do: {:ok, elem(next, 1)}

  defp interpolate_or_exact(current, next, target, _eps),
    do: {:ok, interpolate(current, next, target)}

  defp locate_exact({x, y}, target, eps) do
    if abs(x - target) <= eps, do: {:ok, y}, else: :not_ready
  end

  defp interpolate({x1, y1}, {x2, y2}, target) do
    ratio = (target - x1) / (x2 - x1)
    y1 + ratio * (y2 - y1)
  end

  defp maybe_force_last(%__MODULE__{points: []} = state), do: state

  defp maybe_force_last(%__MODULE__{} = state) do
    last_x = last_point_x(state.points)
    sampler = Sampler.force_target(state.sampler, last_x)
    %{state | sampler: sampler}
  end

  defp last_point_x([]), do: nil
  defp last_point_x(points), do: points |> List.last() |> elem(0)
end
