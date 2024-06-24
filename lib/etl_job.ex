if Code.ensure_loaded?(Oban) do
  defmodule ExEtlFramework.ETLJob do
    # use Oban.Worker, queue: :etl

    # @impl Oban.Worker
    # def perform(%Oban.Job{args: %{"pipeline" => pipeline_module, "attributes" => attributes, "opts" => opts}}) do
    #   module = String.to_existing_atom(pipeline_module)
    #   attributes = Jason.decode!(attributes)
    #   opts = Jason.decode!(opts)

    #   case apply(module, :run, [attributes, opts]) do
    #     {:ok, result} ->
    #       {:ok, result}
    #     {:error, stage, reason} ->
    #       {:error, "ETL failed at #{stage} stage: #{inspect(reason)}"}
    #   end
    # end
  end
end
