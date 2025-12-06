defmodule Fplab1.Sampler do
  @moduledoc """
  Generates monotonically increasing sampling points with optional final target.
  """

  @enforce_keys [:step]
  defstruct step: 1.0, next_x: nil, forced: nil, last_output: nil

  @type t :: %__MODULE__{
          step: float(),
          next_x: float() | nil,
          forced: float() | nil,
          last_output: float() | nil
        }

  @epsilon 1.0e-9

  @spec new(float()) :: t()
  def new(step) when step > 0 do
    %__MODULE__{step: step}
  end

  @spec prime(t(), float()) :: t()
  def prime(%__MODULE__{next_x: nil} = sampler, value), do: %{sampler | next_x: value}
  def prime(sampler, _value), do: sampler

  @spec next_target(t(), float() | nil) :: {:ok, float()} | :not_ready
  def next_target(_sampler, nil), do: :not_ready

  def next_target(%__MODULE__{} = sampler, max_x) do
    case peek(sampler) do
      {:ok, value} ->
        if value <= max_x + @epsilon do
          {:ok, value}
        else
          :not_ready
        end

      :empty ->
        :not_ready
    end
  end

  @spec advance(t()) :: t()
  def advance(%__MODULE__{forced: value} = sampler) when is_number(value) do
    %{sampler | forced: nil, last_output: value}
  end

  def advance(%__MODULE__{next_x: value, step: step} = sampler) when is_number(value) do
    %{sampler | next_x: value + step, last_output: value}
  end

  def advance(sampler), do: sampler

  @spec force_target(t(), float() | nil) :: t()
  def force_target(sampler, nil), do: sampler

  def force_target(%__MODULE__{} = sampler, value) do
    cond do
      sampler.forced && abs(sampler.forced - value) <= @epsilon ->
        sampler

      sampler.last_output && value <= sampler.last_output + @epsilon ->
        sampler

      true ->
        %{sampler | forced: value}
    end
  end

  defp peek(%__MODULE__{forced: value}) when is_number(value), do: {:ok, value}
  defp peek(%__MODULE__{next_x: nil}), do: :empty
  defp peek(%__MODULE__{next_x: value}), do: {:ok, value}
end
