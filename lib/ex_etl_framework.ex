defmodule ExEtlFramework do
  alias ExEtlFramework.{Retry, Validator, AdvancedLogger}

  def run(extractor, transformer, loader, opts \\ []) do
    with {:ok, extracted_data} <- extract_and_validate(extractor, opts),
         {:ok, transformed_data} <- transform_and_validate(transformer, extracted_data, opts),
         {:ok, loaded_result} <- load_and_validate(loader, transformed_data, opts) do
      AdvancedLogger.log(:info, "ETL process completed successfully", %{result: loaded_result})
      {:ok, loaded_result}
    else
      {:error, stage, reason} ->
        AdvancedLogger.log(:error, "ETL process failed", %{stage: stage, reason: reason})
        {:error, stage, reason}
    end
  end

  defp extract_and_validate(extractor, opts) do
    retry_opts = Keyword.get(opts, :extract_retry, [])
    validation_schema = Keyword.get(opts, :extract_validation, %{})

    Retry.retry_with_backoff(
      fn ->
        AdvancedLogger.log(:info, "Starting extraction")
        :telemetry.span([:etl, :extract], %{}, fn ->
          with {:ok, data} <- extractor.(),
               {:ok, validated_data} <- Validator.validate(data, validation_schema) do
            AdvancedLogger.log(:info, "Extraction completed", %{data_size: byte_size(inspect(data))})
            {{:ok, validated_data}, %{}}
          else
            {:error, reason} ->
              AdvancedLogger.log(:error, "Extraction failed", %{reason: reason})
              {{:error, {:extract, reason}}, %{}}
          end
        end)
      end,
      retry_opts
    )
  end

  defp transform_and_validate(transformer, data, opts) do
    retry_opts = Keyword.get(opts, :transform_retry, [])
    validation_schema = Keyword.get(opts, :transform_validation, %{})

    Retry.retry_with_backoff(
      fn ->
        AdvancedLogger.log(:info, "Starting transformation")
        :telemetry.span([:etl, :transform], %{}, fn ->
          with {:ok, transformed} <- transformer.(data),
               {:ok, validated_data} <- Validator.validate(transformed, validation_schema) do
            AdvancedLogger.log(:info, "Transformation completed")
            {{:ok, validated_data}, %{}}
          else
            {:error, reason} ->
              AdvancedLogger.log(:error, "Transformation failed", %{reason: reason})
              {{:error, {:transform, reason}}, %{}}
          end
        end)
      end,
      retry_opts
    )
  end

  defp load_and_validate(loader, data, opts) do
    retry_opts = Keyword.get(opts, :load_retry, [])
    validation_schema = Keyword.get(opts, :load_validation, %{})

    Retry.retry_with_backoff(
      fn ->
        AdvancedLogger.log(:info, "Starting data load")
        :telemetry.span([:etl, :load], %{}, fn ->
          with {:ok, result} <- loader.(data),
               {:ok, validated_result} <- Validator.validate(result, validation_schema) do
            AdvancedLogger.log(:info, "Data load completed")
            {{:ok, validated_result}, %{}}
          else
            {:error, reason} ->
              AdvancedLogger.log(:error, "Data load failed", %{reason: reason})
              {{:error, {:load, reason}}, %{}}
          end
        end)
      end,
      retry_opts
    )
  end
end
