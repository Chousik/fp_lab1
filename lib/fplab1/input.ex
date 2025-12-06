defmodule Fplab1.Input do
  @moduledoc """
  Parses incoming text lines into numeric points.
  """

  @splitter ~r/[\s;,]+/

  @spec parse_line(String.t()) :: {:ok, {float(), float()}} | :skip | {:error, String.t()}
  def parse_line(line) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        :skip

      String.starts_with?(trimmed, "#") ->
        :skip

      true ->
        parse_pair(trimmed)
    end
  end

  defp parse_pair(text) do
    case String.split(text, @splitter, trim: true) do
      [x_text, y_text] ->
        with {:ok, x} <- to_float(x_text),
             {:ok, y} <- to_float(y_text) do
          {:ok, {x, y}}
        else
          :error -> {:error, "Cannot parse numbers from: \"#{text}\""}
        end

      _ ->
        {:error, "Expected two numbers, got: \"#{text}\""}
    end
  end

  defp to_float(text) do
    case Float.parse(text) do
      {value, rest} when rest == "" -> {:ok, value}
      _ -> :error
    end
  end
end
