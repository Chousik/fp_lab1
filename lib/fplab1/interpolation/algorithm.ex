defmodule Fplab1.Interpolation.Algorithm do
  @moduledoc """
  Behaviour for streaming interpolation algorithms.
  """

  @type point :: {float(), float()}
  @type result :: {float(), float()}

  @callback init(keyword()) :: term()
  @callback consume(state :: term(), point()) :: {term(), [result()]}
  @callback finalize(state :: term()) :: {term(), [result()]}
  @callback label(state :: term()) :: String.t()
end
