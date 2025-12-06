defmodule Fplab1.CLI do
  @moduledoc """
  Entry point for the streaming interpolation CLI.
  """

  alias Fplab1.Options
  alias Fplab1.StreamProcessor

  @spec main([String.t()]) :: :ok
  def main(argv) do
    case Options.parse(argv) do
      {:ok, config} ->
        emit = build_emit(config.precision)
        opts = [algorithms: config.algorithms, emit: emit]

        case StreamProcessor.run(IO.stream(:stdio, :line), opts) do
          :ok ->
            :ok

          {:error, message} ->
            IO.puts(:stderr, message)
            exit({:shutdown, 1})
        end

      {:error, message} ->
        IO.puts(:stderr, message)
        exit({:shutdown, 1})

      {:help, usage} ->
        IO.puts(usage)
    end
  end

  defp build_emit(precision) do
    fn label, x, y ->
      IO.puts("#{label}: #{format_number(x, precision)} #{format_number(y, precision)}")
    end
  end

  defp format_number(value, precision) do
    value
    |> :erlang.float_to_binary(decimals: precision)
    |> trim_trailing()
    |> normalize_negative_zero()
  end

  defp trim_trailing(binary) do
    trimmed =
      binary
      |> String.trim_trailing("0")
      |> maybe_trim_dot()

    if trimmed == "" do
      "0"
    else
      trimmed
    end
  end

  defp maybe_trim_dot(binary) do
    if String.ends_with?(binary, ".") do
      String.trim_trailing(binary, ".")
    else
      binary
    end
  end

  defp normalize_negative_zero("-0"), do: "0"
  defp normalize_negative_zero(value), do: value
end
