defmodule BeelineHoneycomb.HoneycombSenderBehaviour do
  @moduledoc """
  A behaviour for `Opencensus.Honeycomb.Sender` that defines the `send_batch/1`
  function used by this library
  """

  @callback send_batch([Opencensus.Honeycomb.Event.t()]) ::
              {:ok, integer()} | {:error, Exception.t()}
end
