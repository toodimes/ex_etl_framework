defmodule ExEtlFrameworkTest do
  use ExUnit.Case
  use ExUnitProperties

  alias ExEtlFramework.{Validator, Pipeline}

  describe "Validator" do
    test "validates required fields" do
      schema = %{name: [&Validator.required/1]}
      assert {:ok, %{name: "John"}} = Validator.validate(%{name: "John"}, schema)
      assert {:error, :name, "Field is required"} = Validator.validate(%{}, schema)
    end

    property "validates types correctly" do
      check all value <- term() do
        expected_type = typeof(value)
        schema = %{field: [Validator.type(expected_type)]}
        result = Validator.validate(%{field: value}, schema)

        case result do
          {:ok, %{field: ^value}} -> assert true
          {:error, :field, message} ->
            flunk("Validation failed for #{inspect(value)} of type #{inspect(expected_type)}: #{message}")
        end
      end
    end

    defp typeof(value) when is_binary(value), do: String
    defp typeof(value) when is_integer(value), do: Integer
    defp typeof(value) when is_float(value), do: Float
    defp typeof(value) when is_boolean(value), do: Boolean
    defp typeof(value) when is_list(value), do: List
    defp typeof(value) when is_map(value), do: Map
    defp typeof(value) when is_atom(value), do: Atom
    defp typeof(value) when is_tuple(value), do: Tuple
    defp typeof(value) when is_function(value), do: Function
    defp typeof(value) when is_pid(value), do: PID
    defp typeof(value) when is_reference(value), do: Reference
    defp typeof(value) when is_port(value), do: Port
    defp typeof(_value), do: Any  # Fallback for any other types
  end

  describe "Pipeline" do
    defmodule TestPipeline do
      use Pipeline

      step :extract do
        {:ok, [1, 2, 3, 4, 5]}
      end

      step :transform do
        {:ok, Enum.map(attributes, &(&1 * 2))}
      end

      step :load do
        {:ok, Enum.sum(attributes)}
      end
    end

    test "runs pipeline successfully" do
      assert {:ok, 30, [], %{}} = TestPipeline.run([])
    end

    test "handles validation errors with :collect_errors strategy" do
      defmodule ErrorPipeline do
        use Pipeline

        step :extract do
          {:ok, [1, 2, 3, 4, 5]}
        end

        step :transform do
          {:ok, Enum.map(attributes, &(&1 * 3))}
        end

        def validate_transform(data) do
          invalid = Enum.filter(data, &(&1 > 8))
          valid = Enum.filter(data, &(&1 <= 8))
          if Enum.empty?(invalid), do: {:ok, data}, else: {:error, invalid, valid}
        end

        step :load do
          {:ok, Enum.sum(attributes)}
        end
      end

      assert {:ok, 9,
      [
        {:transform, 9, "Invalid"},
        {:transform, 12, "Invalid"},
        {:transform, 15, "Invalid"}
      ], _} = ErrorPipeline.run([], error_strategy: :collect_errors)
    end
  end

  describe "Pipeline with Validator" do
    defmodule ValidatedPipeline do
      use Pipeline

      step :extract do
        {:ok, [
          %{id: 1, name: "Alice", age: 30},
          %{id: 2, name: "Bob", age: "25"},  # Age as string to trigger validation error
          %{id: 3, name: "Charlie", age: 35}
        ]}
      end

      def validate_extract(data) do
        schema = %{
          id: [&Validator.required/1, Validator.type(Integer)],
          name: [&Validator.required/1, Validator.type(String)],
          age: [&Validator.required/1, Validator.type(Integer)]
        }

        {valid, invalid} = Enum.reduce(data, {[], []}, fn item, {valid, invalid} ->
          case Validator.validate(item, schema) do
            {:ok, valid_item} -> {[valid_item | valid], invalid}
            {:error, field, reason} ->
              {valid, [{item, "Invalid #{field}: #{reason}"} | invalid]}
          end
        end)

        if Enum.empty?(invalid) do
          {:ok, data}
        else
          {:error, invalid, valid}
        end
      end

      step :transform do
        {:ok, Enum.map(attributes, fn record ->
          Map.update!(record, :age, &(&1 + 1))
        end)}
      end
    end

    test "runs pipeline with validation" do
      result = ValidatedPipeline.run([], error_strategy: :collect_errors)

      {:ok,
        [
          %{age: 36, id: 3, name: "Charlie"},
          %{age: 31, id: 1, name: "Alice"}
        ], errors ,_metrics} = result

      assert [{:extract, %{age: "25", id: 2, name: "Bob"}, "Invalid age: Expected type Integer, got \"25\""}] = errors
    end

    test "pipeline fails fast with invalid data" do
      result = ValidatedPipeline.run([], error_strategy: :fail_fast)

      {:error, :extract,
        [
          {%{age: "25", id: 2, name: "Bob"},
            "Invalid age: Expected type Integer, got \"25\""}
        ], [], _metrics} = result
    end
  end
end
