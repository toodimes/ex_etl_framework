defmodule ExEtlFramework.AdvancedLogger do
  require Logger

  @log_levels [:debug, :info, :warn, :error]

  def log(level, message, metadata \\ %{}) when level in @log_levels do
    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    formatted_message = format_message(level, timestamp, message, metadata)

    Logger.log(level, formatted_message)
    write_to_file(level, formatted_message)
  end

  defp format_message(level, timestamp, message, metadata) do
    metadata_string = format_metadata(metadata)
    "[#{level}] [#{timestamp}] #{message} #{metadata_string}"
  end

  defp format_metadata(metadata) when map_size(metadata) == 0, do: ""
  defp format_metadata(metadata) do
    metadata
    |> Enum.map(fn {k, v} -> "#{k}=#{inspect(v)}" end)
    |> Enum.join(" ")
    |> (fn s -> "| #{s}" end).()
  end

  defp write_to_file(level, message) do
    path = Path.join(log_directory(), "#{level}.log")
    File.write!(path, message <> "\n", [:append])
  end

  defp log_directory do
    directory = Application.get_env(:etl_framework, :log_directory, "log")
    File.mkdir_p!(directory)
    directory
  end
end
