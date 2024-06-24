import Config

config :logger,
  level: :info,
  backends: [:console, {LoggerFileBackend, :error_log}]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :error_log,
  path: "log/error.log",
  level: :error

config :ex_etl_framework,
  log_directory: "log"
