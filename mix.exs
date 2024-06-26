defmodule ExEtlFramework.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :ex_etl_framework,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs()
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.4"},
      {:stream_data, "~> 1.1", only: :test},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  defp docs do
    [
      extras: [
        LICENSE: [title: "License"],
        "README.md": [title: "Readme"]
      ],
      main: "readme",
      source_url: "https://github.com/toodimes/ex_etl_framework",
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp description do
    "An extendable, customizable Elixir ETL framework"
  end

  defp package do
    [
      maintainers: ["David Astor"],
      licenses: ["MIT"],
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      links: %{
        "GitHub" => "https://github.com/toodimes/ex_etl_framework"
      }
    ]
  end
end
