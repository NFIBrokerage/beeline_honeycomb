# Beeline.Honeycomb

![Actions CI](https://github.com/NFIBrokerage/beeline_honeycomb/workflows/Actions%20CI/badge.svg)

a Honeycomb.io exporter for Beeline telemetry

## Installation

```elixir
def deps do
  [
    {:beeline_honeycomb, "~> 1.0"}
  ]
end
```

Check out the docs here: https://hexdocs.pm/beeline_honeycomb

## Usage

Add the `Beeline.Honeycomb` task to your application's supervision tree

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  # ..

  def start(_type, _args) do
    children = [
      # ..
      Beeline.Honeycomb,
      # ..
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```
