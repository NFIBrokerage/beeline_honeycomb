defmodule Beeline.Honeycomb do
  @moduledoc """
  A Honeycomb.io exporter for Beeline telemetry

  This exporter works by attaching a `:telemetry` handler with
  `:telemetry.attach/4`. This attaches a function to handle events to each
  `Beeline.HealthChecker` process. The work of creating and emitting the event
  to Honeycomb is done in the HealthChecker process.

  This module defines a module-based Task which can be started in a supervision
  tree. For example, in your `MyApp.Application`'s `start/2` function, you
  can add this module to the list of `children`:

  ```elixir
  def start(_type, _args) do
    children = [
      {Beeline.Honeycomb, []},
      {MyApp.MyBeelineTopology, []}
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  ## Options

  The `Opencensus.Honeycomb.Event` `:samplerate` key can be configured in the
  keyword list passed to `start_link/1` or as the list in
  `{Beeline.Honeycomb, []}`. `:samplerate` should be a positive integer
  and is defaulted to `1`, meaning that all events are recorded. See
  the `t:Opencensus.Honeycomb.Event.t/0` documentation for more information.
  """

  use Task

  @sender Application.get_env(
            :beeline_honeycomb,
            :honeycomb_sender,
            Opencensus.Honeycomb.Sender
          )

  @doc false
  def start_link(opts) do
    Task.start_link(__MODULE__, :attach, [opts])
  end

  @doc false
  def attach(opts) do
    :telemetry.attach(
      "beeline-honeycomb-exporter",
      [:beeline, :health_check, :stop],
      &__MODULE__.handle_event/4,
      opts
    )
  end

  @doc false
  def handle_event(_event, measurement, metadata, state) do
    previous_local_event_number =
      case metadata[:prior_position] do
        # coveralls-ignore-start
        n when n >= 0 ->
          n

        _ ->
          nil
          # coveralls-ignore-stop
      end

    event = %Opencensus.Honeycomb.Event{
      time: metadata[:measurement_time],
      samplerate: state[:samplerate] || 1,
      data: %{
        event_listener: inspect(metadata[:producer]),
        hostname: metadata[:hostname],
        interval: metadata[:interval],
        drift: metadata[:drift],
        previous_local_event_number: previous_local_event_number,
        local_event_number: metadata[:current_position],
        latest_event_number: metadata[:head_position],
        listener_is_alive: metadata[:alive?],
        listener_has_moved:
          metadata[:current_position] != metadata[:prior_position],
        delta: metadata[:head_position] - metadata[:current_position],
        durationMs:
          System.convert_time_unit(
            measurement.duration,
            :native,
            :microsecond
          ) / 1_000,
        auto_subscribe: metadata[:auto_subscribe]
      }
    }

    @sender.send_batch([event])

    state
  end
end
