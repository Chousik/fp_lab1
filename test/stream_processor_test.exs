defmodule Fplab1.StreamProcessorTest do
  use ExUnit.Case, async: true

  alias Fplab1.StreamProcessor
  alias Fplab1.Interpolation.Linear
  alias Fplab1.Interpolation.Newton

  test "linear interpolation emits samples as data arrives" do
    lines = ["0 0\n", "1 1\n", "2 2\n", "3 3\n"]

    outputs =
      run_stream(lines, [
        {Linear, [step: 0.5, label: "linear"]}
      ])

    assert outputs == [
             {"linear", 0.0, 0.0},
             {"linear", 0.5, 0.5},
             {"linear", 1.0, 1.0},
             {"linear", 1.5, 1.5},
             {"linear", 2.0, 2.0},
             {"linear", 2.5, 2.5},
             {"linear", 3.0, 3.0}
           ]
  end

  test "linear interpolation emits last point even when it is off the grid" do
    lines = ["0 0\n", "3 3\n"]

    outputs =
      run_stream(lines, [
        {Linear, [step: 2.0, label: "linear"]}
      ])

    assert outputs == [
             {"linear", 0.0, 0.0},
             {"linear", 2.0, 2.0},
             {"linear", 3.0, 3.0}
           ]
  end

  test "newton interpolation uses requested order" do
    lines = ["0 0\n", "1 1\n", "2 4\n", "3 9\n", "4 16\n"]

    outputs =
      run_stream(lines, [
        {Newton, [step: 1.0, order: 4, label: "newton"]}
      ])

    assert Enum.take(outputs, 5) == [
             {"newton", 0.0, 0.0},
             {"newton", 1.0, 1.0},
             {"newton", 2.0, 4.0},
             {"newton", 3.0, 9.0},
             {"newton", 4.0, 16.0}
           ]
  end

  test "returns error when x is not strictly increasing" do
    lines = ["0 0\n", "0 1\n"]

    result =
      StreamProcessor.run(lines,
        algorithms: [{Linear, [step: 1.0, label: "linear"]}],
        emit: fn _, _, _ -> :ok end
      )

    assert {:error, message} = result
    assert String.contains?(message, "strictly increasing")
  end

  defp run_stream(lines, algorithms) do
    Process.delete(:outputs)

    emit = fn label, x, y ->
      entries = Process.get(:outputs, [])
      Process.put(:outputs, [{label, x, y} | entries])
    end

    :ok =
      StreamProcessor.run(lines,
        algorithms: algorithms,
        emit: emit
      )

    Process.get(:outputs, []) |> Enum.reverse()
  end
end
