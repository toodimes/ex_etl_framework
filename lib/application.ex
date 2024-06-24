defmodule ExEtlFramework.Application do
  use Application
  import Telemetry.Metrics

  @impl true
  def start(_type, _args) do
    children = [
      {Telemetry.Metrics.ConsoleReporter, metrics: metrics()},
      ExEtlFramework.LogRotator
    ]

    # children =
    #   if Code.ensure_loaded?(Oban) do
    #     children ++ [{Oban, oban_config()}]
    #   else
    #     children
    #   end

    opts = [strategy: :one_for_one, name: ExEtlFramework.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp metrics do
    [
      summary("etl.extract.duration"),
      summary("etl.transform.duration"),
      summary("etl.load.duration")
    ]
  end

  # defp oban_config do
  #   Application.get_env(:etl_framework, Oban, [])
  # end
end
