defmodule ExEtlFramework.Validator do
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

  def required(value) when is_nil(value), do: {:error, "Field is required"}
  def required(_value), do: :ok

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
  defp is_type?(value, Struct), do: is_struct(value)
  defp is_type?(value, NaiveDateTime), do: is_struct(value, NaiveDateTime)
  defp is_type?(value, expected_type), do: is_struct(value, expected_type)
end
