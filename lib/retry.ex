defmodule ExEtlFramework.Retry do
  require Logger

  @default_max_attempts 3
  @default_initial_delay 1000
  @default_max_delay 5000

  def retry_with_backoff(fun, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)
    initial_delay = Keyword.get(opts, :initial_delay, @default_initial_delay)
    max_delay = Keyword.get(opts, :max_delay, @default_max_delay)

    do_retry(fun, 1, max_attempts, initial_delay, max_delay)
  end

  defp do_retry(fun, attempt, max_attempts, delay, max_delay) do
    case fun.() do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        if attempt < max_attempts do
          Logger.warning("Attempt #{attempt} failed: #{inspect(reason)}. Retrying in #{delay}ms.")
          Process.sleep(delay)
          next_delay = min(delay * 2, max_delay)
          do_retry(fun, attempt + 1, max_attempts, next_delay, max_delay)
        else
          Logger.error("All #{max_attempts} attempts failed. Last error: #{inspect(reason)}")
          {:error, reason}
        end
    end
  end
end
