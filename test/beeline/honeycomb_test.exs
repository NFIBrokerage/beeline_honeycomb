defmodule Beeline.HoneycombTest do
  use ExUnit.Case

  import Mox
  setup :verify_on_exit!
  setup :set_mox_global
  @sender Application.compile_env!(:beeline_honeycomb, :honeycomb_sender)

  alias BeelineHoneycomb.MyHandler
  alias Opencensus.Honeycomb.Event

  setup do
    [self: self()]
  end

  test "the health checker periodically checks position and aliveness", c do
    stub(@sender, :send_batch, fn events ->
      send(c.self, {:honeycomb, events})
    end)

    event = %{foo: "bar"}
    events = [event, event]

    _exporter = start_supervised!({Beeline.Honeycomb, samplerate: 1})
    _topology = start_supervised!({MyHandler, test_proc: c.self})

    Beeline.test_events(events, MyHandler)
    assert_receive {:handled, [^event]}
    assert_receive {:handled, [^event]}

    assert_receive {:honeycomb, [%Event{} = event]}, 200
    assert event.data.drift == 0
    assert event.data.interval == 100

    assert event.data.event_listener ==
             "BeelineHoneycomb.MyHandler.Producer_default"

    assert event.data.delta == 0
    assert event.data.latest_event_number == -1
    assert event.data.local_event_number == -1
    assert event.data.previous_local_event_number == nil
    assert event.data.listener_has_moved == false
    assert event.data.listener_is_alive == true
  end
end
