defmodule ExEtlFramework.Pipeline do
  @moduledoc """
  Provides a DSL for defining ETL (Extract, Transform, Load) pipelines.

  This module allows you to define a series of steps that make up your ETL process.
  It handles the execution of these steps, including error handling and performance
  measurement.

  ## Example

      defmodule MyPipeline do
        use ExEtlFramework.Pipeline

        step :extract do
          {:ok, %{data: [1, 2, 3]}}
        end

        step :transform do
          {:ok, %{data: [2, 4, 6]}}
        end

        step :load do
          {:ok, %{result: "Data loaded successfully"}}
        end
      end
  """
  require Logger

  defmacro __using__(_opts) do
    quote do
      import ExEtlFramework.Pipeline
      require Logger
      @before_compile ExEtlFramework.Pipeline
      Module.register_attribute(__MODULE__, :steps, accumulate: true)

      @doc """
      Executes the defined pipeline.

      This function runs all the steps defined in the pipeline in order. It handles
      error strategies and collects metrics for each step.

      ## Parameters

      - `attributes`: Initial data to be passed to the first step.
      - `opts`: Keyword list of options. Supported options:
        - `:error_strategy` - Either `:fail_fast` or `:collect_errors` (default).

      ## Returns

      Returns a tuple with the result of the pipeline execution:
      - `{:ok, final_result, metrics}` if all steps succeed.
      - `{:error, step, reason, errors, metrics}` if any step fails.

      ## Example

          result = MyPipeline.run(%{initial: "data"}, error_strategy: :collect_errors)
      """
      def run(attributes, opts \\ []) do
        steps = __MODULE__.steps() |> Enum.reverse()
        error_strategy = Keyword.get(opts, :error_strategy, :collect_errors)

        Logger.debug("Starting pipeline run with attributes: #{inspect(attributes)}")
        Logger.debug("Steps to execute: #{inspect(steps)}")

        Enum.reduce_while(steps, {:ok, attributes, [], %{}}, fn step, {:ok, acc, errors, metrics} ->
          Logger.debug("Attempting to execute step: #{step}")
          retry_opts = Keyword.get(opts, :"#{step}_retry", [])

          {execution_time, result} = :timer.tc(fn ->
            try do
              ExEtlFramework.Retry.retry_with_backoff(
                fn ->
                  Logger.debug("Applying function for step: #{step}")
                  apply(__MODULE__, step, [acc])
                end,
                retry_opts
              )
            rescue
              e ->
                {:error, step, "Unexpected error: #{inspect(e)}"}
            end
          end)

          step_metrics = Map.put(metrics, step, execution_time / 1_000_000)
          Logger.info("Step #{step} completed in #{execution_time / 1_000_000} seconds")

          Logger.debug("Step #{step} result: #{inspect(result)}")

          case result do
            {:ok, step_result} ->
              if function_exported?(__MODULE__, :"validate_#{step}", 1) do
                Logger.debug("Validating step: #{step}")
                {validation_time, validation_result} = :timer.tc(fn ->
                  apply(__MODULE__, :"validate_#{step}", [step_result])
                end)

                validation_metrics = Map.put(step_metrics, :"#{step}_validation", validation_time / 1_000_000)
                Logger.info("Validation for step #{step} completed in #{validation_time / 1_000_000} seconds")

                case validation_result do
                  {:ok, validated} ->
                    Logger.debug("Validation successful for step: #{step}")
                    {:cont, {:ok, validated, errors, validation_metrics}}
                  {:error, invalid_records, valid_data} ->
                    handle_errors(error_strategy, step, invalid_records, valid_data, errors, validation_metrics)
                end
              else
                {:cont, {:ok, step_result, errors, step_metrics}}
              end
            {:error, reason} ->
              Logger.error("Step #{step} failed, reason: #{inspect(reason)}")
              handle_errors(error_strategy, step, reason, %{}, errors, step_metrics)
          end
        end)
      end

      defp handle_errors(:fail_fast, step, reason, _, errors, metrics) do
        Logger.error("Pipeline failed at step: #{step}, reason: #{inspect(reason)}, errors: #{inspect(errors)}")
        {:halt, {:error, step, reason, errors, metrics}}
      end

      defp handle_errors(:collect_errors, step, invalid_records, valid_data, errors, metrics) do
        new_errors = Enum.map(invalid_records, fn
          {record, reason} -> {step, record, reason}
          # A custom validator may not return a structured {record, reason} so we account for lists with simple data types
          single_record -> {step, single_record, "Invalid"}
        end)
        Logger.warning("Continuing pipeline with valid data. Errors: #{inspect(new_errors)}")
        {:cont, {:ok, valid_data, errors ++ new_errors, metrics}}
      end
    end
  end

  @doc """
  Defines a step in the ETL pipeline.

  This macro is used to define individual steps in your pipeline. Each step
  should return either `{:ok, result}` or `{:error, reason}`.

  ## Parameters

  - `name`: Atom that identifies the step.
  - `do`: The block of code to be executed for this step.

  ## Example

      step :extract do
        {:ok, %{data: [1, 2, 3]}}
      end
  """
  defmacro step(name, do: block) do
    quote do
      @steps unquote(name)
      def unquote(name)(var!(attributes)) do
        Logger.debug("Entering step #{unquote(name)} with attributes: #{inspect(var!(attributes))}")
        result = unquote(block)
        Logger.debug("Exiting step #{unquote(name)} with result: #{inspect(result)}")
        result
      end
    end
  end

  defmacro __before_compile__(env) do
    steps = Module.get_attribute(env.module, :steps)
    quote do
      def steps, do: unquote(Macro.escape(steps))
      Logger.debug("Defined steps: #{inspect(unquote(Macro.escape(steps)))}")
    end
  end
end
