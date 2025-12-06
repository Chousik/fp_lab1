defmodule Fplab1.Interpolation.Newton do
  @moduledoc """
  Newton interpolation over a sliding window of points.
  """

  @behaviour Fplab1.Interpolation.Algorithm

  alias Fplab1.Sampler

  @enforce_keys [:label, :sampler, :order]
  defstruct label: "newton", sampler: Sampler.new(1.0), order: 4, points: []

  @impl true
  def init(opts) do
    step = Keyword.fetch!(opts, :step)
    order = Keyword.fetch!(opts, :order)

    %__MODULE__{
      label: Keyword.get(opts, :label, "newton"),
      sampler: Sampler.new(step),
      order: order,
      points: []
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
        case evaluate(state.points, target, state.order) do
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

  defp evaluate(points, _target, order) when length(points) < order, do: :not_ready

  defp evaluate(points, target, order) do
    window = select_window(points, order, target)

    case window do
      [] -> :not_ready
      _ -> {:ok, newton_value(window, target)}
    end
  end

  defp select_window(points, order, target) do
    total = length(points)

    if total < order do
      []
    else
      idx = find_anchor(points, target)
      half = div(order - 1, 2)
      max_start = total - order
      start_index = idx - half
      start_index = max(start_index, 0)
      start_index = min(start_index, max_start)
      Enum.slice(points, start_index, order)
    end
  end

  defp find_anchor(points, target) do
    points
    |> Enum.find_index(fn {x, _} -> x >= target end)
    |> case do
      nil -> length(points) - 1
      idx -> idx
    end
  end

  defp newton_value(points, target) do
    xs = Enum.map(points, &elem(&1, 0))
    ys = Enum.map(points, &elem(&1, 1))
    coeffs = divided_differences(xs, ys)
    xs_tuple = List.to_tuple(xs)

    coeffs
    |> Enum.with_index()
    |> Enum.reduce(0.0, fn {coeff, idx}, acc ->
      acc + coeff * product_term(xs_tuple, target, idx)
    end)
  end

  defp divided_differences(xs, ys) do
    xs_tuple = List.to_tuple(xs)
    arr = :array.from_list(ys)
    last = length(xs) - 1

    arr =
      Enum.reduce(1..last, arr, fn order, acc ->
        reduce_desc(last, order, acc, fn idx, arr_inner ->
          numerator = :array.get(idx, arr_inner) - :array.get(idx - 1, arr_inner)
          denominator = elem(xs_tuple, idx) - elem(xs_tuple, idx - order)
          value = numerator / denominator
          :array.set(idx, value, arr_inner)
        end)
      end)

    :array.to_list(arr)
  end

  defp reduce_desc(idx, stop, acc, _fun) when idx < stop, do: acc

  defp reduce_desc(idx, stop, acc, fun) do
    acc = fun.(idx, acc)
    reduce_desc(idx - 1, stop, acc, fun)
  end

  defp product_term(_xs, _target, 0), do: 1.0

  defp product_term(xs, target, order) do
    0..(order - 1)
    |> Enum.reduce(1.0, fn idx, acc ->
      acc * (target - elem(xs, idx))
    end)
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
