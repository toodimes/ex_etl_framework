defmodule ExEtlFramework.LogRotator do
  use GenServer
  require Logger

  @rotate_interval :timer.hours(24)  # Rotate logs daily
  @max_log_size 10 * 1024 * 1024  # 10 MB

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_rotation()
    {:ok, state}
  end

  @impl true
  def handle_info(:rotate, state) do
    rotate_logs()
    schedule_rotation()
    {:noreply, state}
  end

  defp schedule_rotation do
    Process.send_after(self(), :rotate, @rotate_interval)
  end

  defp rotate_logs do
    [:debug, :info, :warn, :error]
    |> Enum.each(&rotate_log/1)
  end

  defp rotate_log(level) do
    path = Path.join(log_directory(), "#{level}.log")
    case File.stat(path) do
      {:ok, %{size: size}} when size > @max_log_size ->
        archive_path = "#{path}.#{DateTime.utc_now() |> DateTime.to_date()}"
        File.rename(path, archive_path)
        Logger.info("Rotated #{level} log to #{archive_path}")
      _ ->
        :ok
    end
  end

  defp log_directory do
    Application.get_env(:etl_framework, :log_directory, "log")
  end
end
