defmodule Beeline.Honeycomb do
  @moduledoc """
  a Honeycomb.io exporter for Beeline telemetry
  """

  use Task

  @sender Application.get_env(:beeline_honeycomb, :honeycomb_sender, Opencensus.Honeycomb.Sender)

  @doc false
  def start_link(_opts) do
    Task.start_link(__MODULE__, :attach, [])
  end

  @doc false
  def attach do
    :telemetry.attach(
      "beeline-honeycomb-exporter",
      [:beeline, :health_check, :stop],
      &__MODULE__.handle_event/4,
      :ok
    )
  end

  @doc false
  def handle_event(_event, measurement, metadata, state) do
    event =
      %Opencensus.Honeycomb.Event{
        time: metadata[:measurement_time],
        data: %{
          event_listener: inspect(metadata[:producer]),
          hostname: metadata[:hostname],
          interval: metadata[:interval],
          drift: metadata[:drift],
          previous_local_event_number: metadata[:prior_position],
          local_event_number: metadata[:current_position],
          latest_event_number: metadata[:head_position],
          listener_is_alive: metadata[:alive?],
          listener_has_moved: metadata[:listener_has_moved],
          delta: metadata[:current_position] - metadata[:prior_position],
          durationMs:
            System.convert_time_unit(
              measurement.duration,
              :native,
              :microsecond
            ) / 1_000
        }
      }

    @sender.send_batch([event])

    state
  end
end
