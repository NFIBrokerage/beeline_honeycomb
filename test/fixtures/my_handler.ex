defmodule BeelineHoneycomb.MyHandler do
  @moduledoc """
  An example beeline fixture for the sake of testing which relies on the dummy
  producer
  """

  use Beeline

  def start_link(opts) do
    Beeline.start_link(__MODULE__,
      name: __MODULE__,
      producers: [
        default: [
          adapter: :dummy,
          connection: nil,
          stream_name: "Beeline.Honeycomb.Test"
        ]
      ],
      auto_subscribe?: fn _producer -> true end,
      get_stream_position: fn _producer -> -1 end,
      spawn_health_checkers?: true,
      health_check_interval: 100,
      health_check_drift: 0,
      subscribe_after: 0,
      context: %{test_proc: opts[:test_proc]}
    )
  end

  @impl GenStage
  def handle_events(subscription_events, _from, state) do
    events = Enum.map(subscription_events, &Beeline.decode_event/1)

    send(state.test_proc, {:handled, events})

    {:noreply, [], state}
  end
end
