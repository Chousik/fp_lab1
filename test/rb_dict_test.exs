defmodule Fplab1.RBDictTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Fplab1.RBDict

  describe "basic API" do
    test "put, fetch and member?" do
      dict =
        RBDict.new()
        |> RBDict.put(:b, 2)
        |> RBDict.put(:a, 1)
        |> RBDict.put(:b, 3)

      assert RBDict.size(dict) == 2
      assert RBDict.fetch!(dict, :a) == 1
      assert RBDict.fetch!(dict, :b) == 3
      refute RBDict.member?(dict, :c)
    end

    test "delete removes only target key" do
      dict =
        RBDict.new()
        |> RBDict.put(:keep, 1)
        |> RBDict.put(:drop, 2)
        |> RBDict.delete(:drop)
        |> RBDict.delete(:missing)

      assert RBDict.size(dict) == 1
      assert RBDict.get(dict, :keep) == 1
      refute RBDict.member?(dict, :drop)
    end

    test "map and filter" do
      dict = RBDict.from_enum([{:a, 1}, {:b, 2}, {:c, 3}])

      mapped = RBDict.map(dict, fn _k, v -> v * 2 end)
      filtered = RBDict.filter(mapped, fn k, _v -> k != :b end)

      assert RBDict.to_list(filtered) == [a: 2, c: 6]
    end

    test "folds respect ordering" do
      dict = RBDict.from_enum([{:b, 2}, {:a, 1}, {:c, 3}])

      assert RBDict.foldl(dict, [], fn {k, _v}, acc -> [k | acc] end) == [:c, :b, :a]
      assert RBDict.foldr(dict, [], fn {k, _v}, acc -> [k | acc] end) == [:a, :b, :c]
    end

    test "equality ignores internal structure" do
      dict1 = RBDict.from_enum(Enum.shuffle([{:a, 1}, {:b, 2}, {:c, 3}]))
      dict2 = RBDict.from_enum(Enum.reverse([{:a, 1}, {:b, 2}, {:c, 3}]))

      assert RBDict.equal?(dict1, dict2)
    end
  end

  describe "properties" do
    test "building from enum matches Map semantics" do
      check all(pairs <- kv_pairs()) do
        dict = RBDict.from_enum(pairs)

        expected =
          pairs
          |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
          |> Map.to_list()
          |> Enum.sort()

        assert RBDict.to_list(dict) == expected
      end
    end

    test "map mirrors Enum.map over values" do
      check all(pairs <- kv_pairs()) do
        dict = RBDict.from_enum(pairs)

        mapped = RBDict.map(dict, fn _k, v -> v * 2 end)

        expected =
          pairs
          |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, k, v * 2) end)
          |> Map.to_list()
          |> Enum.sort()

        assert RBDict.to_list(mapped) == expected
      end
    end

    test "filter keeps only matching entries" do
      check all(pairs <- kv_pairs()) do
        dict = RBDict.from_enum(pairs)
        filtered = RBDict.filter(dict, fn k, _v -> rem(k, 2) == 0 end)

        expected =
          pairs
          |> Enum.reduce(%{}, fn {k, v}, acc ->
            if rem(k, 2) == 0, do: Map.put(acc, k, v), else: acc
          end)
          |> Map.to_list()
          |> Enum.sort()

        assert RBDict.to_list(filtered) == expected
      end
    end

    test "monoid associativity and identity" do
      check all(
              list1 <- kv_pairs(),
              list2 <- kv_pairs(),
              list3 <- kv_pairs()
            ) do
        d1 = RBDict.from_enum(list1)
        d2 = RBDict.from_enum(list2)
        d3 = RBDict.from_enum(list3)

        left = d1 |> RBDict.concat(d2) |> RBDict.concat(d3)
        right = RBDict.concat(d1, RBDict.concat(d2, d3))

        assert RBDict.equal?(left, right)
        assert RBDict.equal?(RBDict.concat(left, RBDict.identity()), left)
        assert RBDict.equal?(RBDict.concat(RBDict.identity(), left), left)
      end
    end

    test "foldl behaves like Enum.reduce" do
      check all(pairs <- kv_pairs()) do
        dict = RBDict.from_enum(pairs)
        list = RBDict.to_list(dict)

        assert RBDict.foldl(dict, 0, fn {_k, v}, acc -> acc + v end) ==
                 Enum.reduce(list, 0, fn {_k, v}, acc -> acc + v end)

        assert RBDict.foldr(dict, 0, fn {_k, v}, acc -> acc + v end) ==
                 Enum.reduce(Enum.reverse(list), 0, fn {_k, v}, acc -> acc + v end)
      end
    end
  end

  defp kv_pairs do
    pair_gen =
      StreamData.tuple({StreamData.integer(-1000..1000), StreamData.integer(-1000..1000)})

    StreamData.list_of(pair_gen, max_length: 40)
  end
end
