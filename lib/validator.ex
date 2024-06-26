defmodule ExEtlFramework.Validator do
  @moduledoc """
  Provides functions for validating data structures.

  This module offers a flexible way to define validation rules and apply them
  to your data. It's particularly useful for ensuring data integrity at various
  stages of your ETL pipeline.

  ## Example

      schema = %{
        name: [&Validator.required/1, &Validator.type(String)],
        age: [&Validator.type(Integer)]
      }
      Validator.validate(%{name: "John", age: 30}, schema)
  """

  @doc """
  Validates data against a given schema.

  ## Parameters

  - `data`: The data structure to validate.
  - `schema`: A map where keys are field names and values are lists of validator functions.

  ## Returns

  Returns either:
  - `{:ok, data}` if all validations pass.
  - `{:error, field, reason}` if any validation fails.

  ## Example

      schema = %{name: [&Validator.required/1, &Validator.type(String)]}
      Validator.validate(%{name: "John"}, schema)
  """
  def validate(data, schema) do
    Enum.reduce_while(schema, {:ok, data}, fn {field, validators}, {:ok, acc} ->
      case validate_field(data, field, validators) do
        :ok -> {:cont, {:ok, acc}}
        {:error, reason} -> {:halt, {:error, field, reason}}
        {:error, failed_field, reason} -> {:halt, {:error, failed_field, reason}}
      end
    end)
  end

  defp validate_field(data, field, validators) when is_list(validators) do
    value = Map.get(data, field)
    Enum.reduce_while(validators, :ok, fn validator, _acc ->
      case validator.(value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
        other ->
          {:halt, other}
      end
    end)
  end

  @doc """
  Validates that a value is not nil.

  ## Parameters

  - `value`: The value to check.

  ## Returns

  Returns either:
  - `:ok` if the value is not nil.
  - `{:error, "Field is required"}` if the value is nil.

  ## Example

      Validator.required("Some value")  # Returns :ok
      Validator.required(nil)           # Returns {:error, "Field is required"}
  """
  def required(value) when is_nil(value), do: {:error, "Field is required"}
  def required(_value), do: :ok

  @doc """
  Creates a validator function that checks if a value is of a specific type.

  ## Parameters

  - `expected_type`: The type to check against (e.g., String, Integer).

  ## Returns

  Returns a function that takes a value and returns:
  - `:ok` if the value is of the expected type or nil.
  - `{:error, reason}` if the value is not of the expected type.

  ## Example

      string_validator = Validator.type(String)
      string_validator.("Hello")  # Returns :ok
      string_validator.(123)      # Returns {:error, "Expected type String, got 123"}
  """
  def type(expected_type) do
    fn value ->
      if is_nil(value) or is_type?(value, expected_type) do
        :ok
      else
        {:error, "Expected type #{inspect(expected_type)}, got #{inspect(value)}"}
      end
    end
  end

  defp is_type?(value, String), do: is_binary(value)
  defp is_type?(value, Integer), do: is_integer(value)
  defp is_type?(value, Float), do: is_float(value)
  defp is_type?(value, Number), do: is_number(value)
  defp is_type?(value, Atom), do: is_atom(value)
  defp is_type?(value, List), do: is_list(value)
  defp is_type?(value, Boolean), do: is_boolean(value)
  defp is_type?(value, Tuple), do: is_tuple(value)
  defp is_type?(value, Map), do: is_map(value)
  defp is_type?(value, Function), do: is_function(value)
  defp is_type?(value, PID), do: is_pid(value)
  defp is_type?(value, Port), do: is_port(value)
  defp is_type?(value, Reference), do: is_reference(value)
  defp is_type?(_value, Any), do: true
  defp is_type?(value, expected_type), do: is_struct(value, expected_type)
end
