defmodule ExEtlFramework.Application do
  use Application
  import Telemetry.Metrics

  @impl true
  def start(_type, _args) do
    children = [
      {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    opts = [strategy: :one_for_one, name: ExEtlFramework.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp metrics do
    [
      summary("pipeline.run.duration"),
      summary("pipeline.step.duration", tags: [:step]),
      counter("pipeline.errors.total", tags: [:step])
    ]
  end
end
