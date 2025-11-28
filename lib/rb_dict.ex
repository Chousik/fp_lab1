defmodule Fplab1.RBDict do
  @moduledoc """
  Простой неизменяемый словарь на основе сбалансированного дерева (`:gb_trees`).

  Модуль предоставляет минимально необходимый API: создание пустой структуры,
  вставку/удаление, фильтрацию, отображение значений, левую и правую свёртки.
  Кроме того, словарь образует моноид — `new/0` это нейтральный элемент, а
  `concat/2` (и `concat/1`) ассоциативно объединяют словари.
  """

  @enforce_keys [:tree]
  defstruct tree: :gb_trees.empty()

  @type key :: term()
  @type value :: term()
  @type t :: %__MODULE__{tree: :gb_trees.tree()}

  @doc "Создаёт пустой словарь"
  @spec new() :: t()
  def new, do: %__MODULE__{tree: :gb_trees.empty()}

  @doc "Моноидальный нейтральный элемент"
  @spec identity() :: t()
  def identity, do: new()

  @doc "Количество элементов"
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{tree: tree}), do: :gb_trees.size(tree)

  @doc "Проверяет, пуст ли словарь"
  @spec empty?(t()) :: boolean()
  def empty?(dict), do: size(dict) == 0

  @doc "Получает значение по ключу"
  @spec fetch(t(), key()) :: {:ok, value()} | :error
  def fetch(%__MODULE__{tree: tree}, key) do
    case :gb_trees.lookup(key, tree) do
      {:value, value} -> {:ok, value}
      :none -> :error
    end
  end

  @doc "Аналог `fetch/2`, но возвращает значение или `default`"
  @spec get(t(), key(), value() | nil) :: value() | nil
  def get(dict, key, default \\ nil) do
    case fetch(dict, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc "Аналог `fetch/2`, но выбрасывает `KeyError` при отсутствии ключа"
  @spec fetch!(t(), key()) :: value()
  def fetch!(dict, key) do
    case fetch(dict, key) do
      {:ok, value} -> value
      :error -> raise KeyError, key: key, term: __MODULE__
    end
  end

  @doc "Проверяет наличие ключа"
  @spec member?(t(), key()) :: boolean()
  def member?(dict, key) do
    match?({:ok, _}, fetch(dict, key))
  end

  @doc "Вставляет или заменяет значение"
  @spec put(t(), key(), value()) :: t()
  def put(%__MODULE__{tree: tree}, key, value) do
    %__MODULE__{tree: :gb_trees.enter(key, value, tree)}
  end

  @doc "Удаляет ключ (если он есть)"
  @spec delete(t(), key()) :: t()
  def delete(%__MODULE__{tree: tree}, key) do
    %__MODULE__{tree: :gb_trees.delete_any(key, tree)}
  end

  @doc "Применяет функцию к каждому значению"
  @spec map(t(), (key(), value() -> value())) :: t()
  def map(%__MODULE__{} = dict, fun) when is_function(fun, 2) do
    dict
    |> to_list()
    |> Enum.map(fn {k, v} -> {k, fun.(k, v)} end)
    |> from_enum()
  end

  @doc "Оставляет только элементы, удовлетворяющие предикату"
  @spec filter(t(), (key(), value() -> as_boolean(term()))) :: t()
  def filter(%__MODULE__{} = dict, pred) when is_function(pred, 2) do
    dict
    |> to_list()
    |> Enum.filter(fn {k, v} -> pred.(k, v) end)
    |> from_enum()
  end

  @doc "Левая свёртка (ключи в порядке возрастания)"
  @spec foldl(t(), acc, ({key(), value()}, acc -> acc)) :: acc when acc: term()
  def foldl(%__MODULE__{} = dict, acc, fun) do
    dict
    |> to_list()
    |> Enum.reduce(acc, fn {k, v}, acc -> fun.({k, v}, acc) end)
  end

  @doc "Правая свёртка (ключи по убыванию)"
  @spec foldr(t(), acc, ({key(), value()}, acc -> acc)) :: acc when acc: term()
  def foldr(%__MODULE__{} = dict, acc, fun) do
    dict
    |> to_list()
    |> Enum.reverse()
    |> Enum.reduce(acc, fn {k, v}, acc -> fun.({k, v}, acc) end)
  end

  @doc "Строит словарь из перечислимого набора пар"
  @spec from_enum(Enum.t()) :: t()
  def from_enum(enum) do
    Enum.reduce(enum, new(), fn {k, v}, acc -> put(acc, k, v) end)
  end

  @doc "Возвращает пары ключ-значение в порядке возрастания ключей"
  @spec to_list(t()) :: [{key(), value()}]
  def to_list(%__MODULE__{tree: tree}) do
    :gb_trees.to_list(tree)
  end

  @doc "Моноидальное объединение двух словарей"
  @spec concat(t(), t()) :: t()
  def concat(%__MODULE__{} = left, %__MODULE__{} = right) do
    Enum.reduce(to_list(right), left, fn {k, v}, acc -> put(acc, k, v) end)
  end

  @doc "Моноидальное объединение набора словарей"
  @spec concat([t()]) :: t()
  def concat(dicts) when is_list(dicts) do
    Enum.reduce(dicts, new(), &concat/2)
  end

  @doc "Эффективное сравнение без промежуточных списков"
  @spec equal?(t(), t()) :: boolean()
  def equal?(%__MODULE__{tree: left}, %__MODULE__{tree: right}) do
    iterator_equal?(:gb_trees.iterator(left), :gb_trees.iterator(right))
  end

  defp iterator_equal?(:none, :none), do: true
  defp iterator_equal?(:none, _), do: false
  defp iterator_equal?(_, :none), do: false

  defp iterator_equal?(iter1, iter2) do
    case {:gb_trees.next(iter1), :gb_trees.next(iter2)} do
      {:none, :none} -> true
      {{key1, value1, next1}, {key2, value2, next2}} when key1 == key2 and value1 == value2 ->
        iterator_equal?(next1, next2)

      _ ->
        false
    end
  end
end
