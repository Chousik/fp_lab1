defmodule Fplab1.InputTest do
  use ExUnit.Case, async: true

  alias Fplab1.Input

  test "parses pairs separated by whitespace" do
    assert Input.parse_line("1 2\n") == {:ok, {1.0, 2.0}}
    assert Input.parse_line("3\t4") == {:ok, {3.0, 4.0}}
  end

  test "parses pairs separated by semicolon" do
    assert Input.parse_line("5;6") == {:ok, {5.0, 6.0}}
  end

  test "skips empty lines and comments" do
    assert Input.parse_line("\n") == :skip
    assert Input.parse_line("# comment") == :skip
  end

  test "returns error for invalid data" do
    assert {:error, _} = Input.parse_line("not-a-number")
  end
end
