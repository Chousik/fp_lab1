defmodule Fplab1.Options do
  @moduledoc """
  Parses command line options for the interpolation CLI.
  """

  alias Fplab1.Interpolation.Linear
  alias Fplab1.Interpolation.Newton

  @default_step 1.0
  @default_order 4
  @default_precision 6

  @doc """
  Parses `argv` and returns either `{:ok, config}` or an error/help tuple.
  """
  @spec parse([String.t()]) :: {:ok, map()} | {:error, String.t()} | {:help, String.t()}
  def parse(argv) do
    {opts, _, invalid} =
      OptionParser.parse(argv,
        strict: [
          help: :boolean,
          step: :float,
          order: :integer,
          precision: :integer,
          linear: :boolean,
          newton: :boolean
        ],
        aliases: [
          h: :help,
          s: :step,
          n: :order,
          p: :precision
        ]
      )

    cond do
      opts[:help] ->
        {:help, usage()}

      invalid != [] ->
        {:error, "Unknown options: #{format_invalid(invalid)}"}

      true ->
        build_config(opts)
    end
  end

  defp build_config(opts) do
    with {:ok, step} <- positive_float(opts[:step] || @default_step, "step"),
         {:ok, order} <- min_points(opts[:order] || @default_order),
         {:ok, precision} <-
           non_negative_integer(opts[:precision] || @default_precision, "precision") do
      algorithms = choose_algorithms(opts, step, order)

      {:ok,
       %{
         algorithms: algorithms,
         precision: precision
       }}
    end
  end

  defp choose_algorithms(opts, step, order) do
    choices =
      []
      |> maybe_add(:linear, opts[:linear])
      |> maybe_add(:newton, opts[:newton])

    selected = if choices == [], do: [:linear], else: choices

    Enum.map(selected, fn
      :linear -> {Linear, [step: step, label: "linear"]}
      :newton -> {Newton, [step: step, label: "newton", order: order]}
    end)
  end

  defp maybe_add(list, _tag, flag) when flag in [nil, false], do: list
  defp maybe_add(list, tag, _flag), do: list ++ [tag]

  defp positive_float(value, name) do
    if value > 0 do
      {:ok, value}
    else
      {:error, "Option --#{name} must be positive"}
    end
  end

  defp min_points(value) when value < 2, do: {:error, "Option --order must be at least 2"}
  defp min_points(value), do: {:ok, value}

  defp non_negative_integer(value, name) when value < 0,
    do: {:error, "Option --#{name} must not be negative"}

  defp non_negative_integer(value, _name), do: {:ok, value}

  defp format_invalid(invalid) do
    Enum.map_join(invalid, ", ", fn {switch, _} -> switch end)
  end

  defp usage do
    """
    Usage: my_lab3 [options]

    --linear            enable piece-wise linear interpolation (default)
    --newton            enable Newton interpolation alongside linear
    --step, -s VALUE    sampling step (default: #{@default_step})
    --order, -n VALUE   number of points for Newton interpolation (default: #{@default_order})
    --precision, -p N   decimal places in the output (default: #{@default_precision})
    --help, -h          print this help message
    """
    |> String.trim_trailing()
  end
end
