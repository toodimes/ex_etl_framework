import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ex_etl_framework,
  log_directory: "log"
