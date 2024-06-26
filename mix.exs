defmodule ExEtlFramework.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_etl_framework,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExEtlFramework.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      {:stream_data, "~> 1.1", only: :test}
    ]
  end
end
