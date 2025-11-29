defmodule Fplab1.RBDict do
  @moduledoc """
  Реализация rb-dict на основе красно-чёрного дерева. Узлы
  представлены кортежами `{:node, color, key, value, left, right}`.
  """

  @type color :: :red | :black
  @type key :: term()
  @type value :: term()
  @type tree :: nil | {:node, color(), key(), value(), tree(), tree()}

  # --- базовые операции ----------------------------------------------------

  @spec new() :: tree()
  def new(), do: nil

  @spec identity() :: tree()
  def identity(), do: new()

  @spec empty?(tree()) :: boolean()
  def empty?(nil), do: true
  def empty?(_), do: false

  @spec size(tree()) :: non_neg_integer()
  def size(nil), do: 0
  def size({:node, _c, _k, _v, left, right}), do: 1 + size(left) + size(right)

  @spec fetch(tree(), key()) :: {:ok, value()} | :error
  def fetch(nil, _), do: :error

  def fetch({:node, _c, key, value, left, right}, target) do
    cond do
      target < key -> fetch(left, target)
      target > key -> fetch(right, target)
      true -> {:ok, value}
    end
  end

  @spec fetch!(tree(), key()) :: value()
  def fetch!(tree, key) do
    case fetch(tree, key) do
      {:ok, value} -> value
      :error -> raise KeyError, key: key, term: __MODULE__
    end
  end

  @spec get(tree(), key(), value() | nil) :: value() | nil
  def get(tree, key, default \\ nil) do
    case fetch(tree, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @spec member?(tree(), key()) :: boolean()
  def member?(tree, key) do
    match?({:ok, _}, fetch(tree, key))
  end

  @spec put(tree(), key(), value()) :: tree()
  def put(tree, key, value) do
    tree
    |> insert(key, value)
    |> blacken()
  end

  @spec delete(tree(), key()) :: tree()
  def delete(tree, key) do
    {root, _} = delete_node(tree, key)
    blacken(root)
  end

  @spec map(tree(), (key(), value() -> value())) :: tree()
  def map(nil, _fun), do: nil

  def map({:node, color, key, value, left, right}, fun) do
    {:node, color, key, fun.(key, value), map(left, fun), map(right, fun)}
  end

  @spec filter(tree(), (key(), value() -> as_boolean(term()))) :: tree()
  def filter(tree, predicate) do
    tree
    |> to_list()
    |> Enum.filter(fn {k, v} -> predicate.(k, v) end)
    |> from_enum()
  end

  @spec foldl(tree(), acc, ({key(), value()}, acc -> acc)) :: acc when acc: term()
  def foldl(tree, acc, fun) do
    case tree do
      nil -> acc
      {:node, _c, key, value, left, right} ->
        acc1 = foldl(left, acc, fun)
        acc2 = fun.({key, value}, acc1)
        foldl(right, acc2, fun)
    end
  end

  @spec foldr(tree(), acc, ({key(), value()}, acc -> acc)) :: acc when acc: term()
  def foldr(tree, acc, fun) do
    case tree do
      nil -> acc
      {:node, _c, key, value, left, right} ->
        acc1 = foldr(right, acc, fun)
        acc2 = fun.({key, value}, acc1)
        foldr(left, acc2, fun)
    end
  end

  @spec from_enum(Enum.t()) :: tree()
  def from_enum(enum) do
    Enum.reduce(enum, new(), fn {k, v}, acc -> put(acc, k, v) end)
  end

  @spec to_list(tree()) :: [{key(), value()}]
  def to_list(tree), do: do_to_list(tree, [])

  defp do_to_list(nil, acc), do: acc

  defp do_to_list({:node, _c, key, value, left, right}, acc) do
    acc1 = do_to_list(right, acc)
    acc2 = [{key, value} | acc1]
    do_to_list(left, acc2)
  end

  @spec concat(tree(), tree()) :: tree()
  def concat(left, right) do
    Enum.reduce(to_list(right), left, fn {k, v}, acc -> put(acc, k, v) end)
  end

  @spec concat([tree()]) :: tree()
  def concat(dicts) when is_list(dicts) do
    Enum.reduce(dicts, new(), fn dict, acc -> concat(acc, dict) end)
  end

  @spec equal?(tree(), tree()) :: boolean()
  def equal?(left, right) do
    compare_inorder(push_left(left, []), push_left(right, []))
  end

  defp push_left(nil, stack), do: stack

  defp push_left({:node, _c, key, value, left, right}, stack) do
    push_left(left, [{key, value, right} | stack])
  end

  defp compare_inorder([], []), do: true
  defp compare_inorder([], _), do: false
  defp compare_inorder(_, []), do: false

  defp compare_inorder([{k1, v1, r1} | rest1], [{k2, v2, r2} | rest2]) do
    if k1 == k2 and v1 == v2 do
      compare_inorder(push_left(r1, rest1), push_left(r2, rest2))
    else
      false
    end
  end

  # --- вставка -------------------------------------------------------------

  defp insert(nil, key, value), do: {:node, :red, key, value, nil, nil}

  defp insert({:node, color, key, value, left, right}, target_key, target_value) do
    {new_left, new_right, new_value} =
      cond do
        target_key < key -> {insert(left, target_key, target_value), right, value}
        target_key > key -> {left, insert(right, target_key, target_value), value}
        true -> {left, right, target_value}
      end

    {:node, color, key, new_value, new_left, new_right}
    |> balance()
  end

  # --- удаление ------------------------------------------------------------

  defp delete_node(nil, _key), do: {nil, false}

  defp delete_node({:node, _color, key, _value, left, _right} = node, target) do
    cond do
      target < key ->
        node1 =
          if left != nil and not red?(left) and not red?(left_left(left)) do
            move_red_left(node)
          else
            node
          end

        {new_left, removed?} = delete_node(left_child(node1), target)
        {fix_up(set_left(node1, new_left)), removed?}

      true ->
        node1 = if red?(left), do: rotate_right(node), else: node

        cond do
          target == node_key(node1) and right_child(node1) == nil ->
            {nil, true}

          true ->
            node2 =
              if right_child(node1) != nil and not red?(right_child(node1)) and not red?(left_left(right_child(node1))) do
                move_red_right(node1)
              else
                node1
              end

            if target == node_key(node2) do
              {min_key, min_value} = min_kv(right_child(node2))
              {new_right, _} = delete_min(right_child(node2))
              node3 = {:node, node_color(node2), min_key, min_value, left_child(node2), new_right}
              {fix_up(node3), true}
            else
              {new_right, removed?} = delete_node(right_child(node2), target)
              {fix_up(set_right(node2, new_right)), removed?}
            end
        end
    end
  end

  defp delete_min(nil), do: {nil, false}

  defp delete_min({:node, _c, _k, _v, nil, right}), do: {right, true}

  defp delete_min(node) do
    node1 =
      if left_child(node) != nil and not red?(left_child(node)) and not red?(left_left(left_child(node))) do
        move_red_left(node)
      else
        node
      end

    {new_left, removed?} = delete_min(left_child(node1))
    {fix_up(set_left(node1, new_left)), removed?}
  end

  defp left_left(nil), do: nil
  defp left_left({:node, _c, _k, _v, left, _r}), do: left_child(left)

  # --- балансировка --------------------------------------------------------

  defp balance(node) do
    node
    |> maybe_rotate_left()
    |> maybe_rotate_right()
    |> maybe_flip_colors()
  end

  defp fix_up(node) do
    node
    |> maybe_rotate_left()
    |> maybe_rotate_right()
    |> maybe_flip_colors()
  end

  defp maybe_rotate_left(node) do
    if red?(right_child(node)) and not red?(left_child(node)) do
      rotate_left(node)
    else
      node
    end
  end

  defp maybe_rotate_right(node) do
    if red?(left_child(node)) and red?(left_child(left_child(node))) do
      rotate_right(node)
    else
      node
    end
  end

  defp maybe_flip_colors(node) do
    if red?(left_child(node)) and red?(right_child(node)) do
      flip_colors(node)
    else
      node
    end
  end

  defp move_red_left(node) do
    node1 = flip_colors(node)

    if red?(left_child(right_child(node1))) do
      node2 = set_right(node1, rotate_right(right_child(node1)))
      flip_colors(rotate_left(node2))
    else
      node1
    end
  end

  defp move_red_right(node) do
    node1 = flip_colors(node)

    if red?(left_child(left_child(node1))) do
      flip_colors(rotate_right(node1))
    else
      node1
    end
  end

  defp rotate_left({:node, color, key, value, left, {:node, :red, rkey, rvalue, rleft, rright}}) do
    {:node, color, rkey, rvalue, {:node, :red, key, value, left, rleft}, rright}
  end

  defp rotate_right({:node, color, key, value, {:node, :red, lkey, lvalue, lleft, lright}, right}) do
    {:node, color, lkey, lvalue, lleft, {:node, :red, key, value, lright, right}}
  end

  defp flip_colors({:node, color, key, value, left, right}) do
    {:node, flip(color), key, value, recolor(left), recolor(right)}
  end

  defp recolor(nil), do: nil
  defp recolor({:node, color, key, value, left, right}), do: {:node, flip(color), key, value, left, right}

  defp flip(:red), do: :black
  defp flip(:black), do: :red

  # --- вспомогательные функции --------------------------------------------

  defp red?(nil), do: false
  defp red?({:node, color, _k, _v, _l, _r}), do: color == :red

  defp left_child(nil), do: nil
  defp left_child({:node, _c, _k, _v, left, _r}), do: left

  defp right_child(nil), do: nil
  defp right_child({:node, _c, _k, _v, _l, right}), do: right

  defp set_left({:node, color, key, value, _old_left, right}, new_left) do
    {:node, color, key, value, new_left, right}
  end

  defp set_right({:node, color, key, value, left, _old_right}, new_right) do
    {:node, color, key, value, left, new_right}
  end

  defp node_key({:node, _c, key, _v, _l, _r}), do: key
  defp node_color({:node, color, _k, _v, _l, _r}), do: color

  defp min_kv({:node, _c, key, value, nil, _r}), do: {key, value}
  defp min_kv({:node, _c, _k, _v, left, _r}), do: min_kv(left)

  defp blacken(nil), do: nil
  defp blacken({:node, _c, key, value, left, right}), do: {:node, :black, key, value, left, right}
end
