# ExEtlFramework

ExEtlFramework is an Elixir-based ETL (Extract, Transform, Load) framework designed to simplify and streamline data processing pipelines. It provides a set of tools for building flexible and measurable ETL processes.

## Features

- **Modular Pipeline Structure**: Define ETL steps using a simple DSL.
- **Data Validation**: Flexible schema-based data validation.
- **Error Handling Strategies**: Choose between fail-fast or error collection approaches.
- **Telemetry Integration**: Measure and report on pipeline performance.

## Installation

Add `ex_etl_framework` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_etl_framework, "~> 0.1.0"}
  ]
end
```

## Usage

### Defining a Pipeline

```elixir
defmodule MyPipeline do
  use ExEtlFramework.Pipeline

  step :extract do
    # Extraction logic
    {:ok, %{data: [1, 2, 3]}}
  end

  step :transform do
    # Transformation logic
    {:ok, %{data: [2, 4, 6]}}
  end

  step :load do
    # Loading logic
    {:ok, %{result: "Data loaded successfully"}}
  end

  # Optional: Define validation for each step
  def validate_extract(data) do
    # Validation logic
  end
end
```

### Running a Pipeline

```elixir
result = MyPipeline.run(%{initial: "data"}, error_strategy: :collect_errors)
```

## Components

### Pipeline

The core of the framework, allowing you to define and execute ETL steps.

## Validator

The Validator module provides a flexible and powerful way to validate data within your ETL pipeline. It allows you to define validation schemas and apply them to your data at any step of the process.

### Defining a Schema

A schema is a map where keys are field names and values are lists of validation functions. Here's an example:

```elixir
schema = %{
  name: [&ExEtlFramework.Validator.required/1, &ExEtlFramework.Validator.type(String)],
  age: [&ExEtlFramework.Validator.type(Integer)],
  email: [&ExEtlFramework.Validator.required/1, &custom_email_validator/1]
}
```

### Built-in Validators

ExEtlFramework.Validator provides several built-in validation functions:

- `required/1`: Ensures the field is present and not nil.
- `type/1`: Checks if the value is of a specific type.

### Custom Validators

You can easily define custom validation functions. They should return `:ok` for valid data or `{:error, reason}` for invalid data:

```elixir
def custom_email_validator(value) do
  if String.contains?(value, "@") do
    :ok
  else
    {:error, "Invalid email format"}
  end
end
```

### Applying Validation

To apply validation in your pipeline, use the `validate/2` function:

```elixir
defmodule MyPipeline do
  use ExEtlFramework.Pipeline
  alias ExEtlFramework.Validator

  step :extract do
    {:ok, %{name: "John Doe", age: 30, email: "john@example.com"}}
  end

  def validate_extract(data) do
    schema = %{
      name: [&Validator.required/1, &Validator.type(String)],
      age: [&Validator.type(Integer)],
      email: [&Validator.required/1, &custom_email_validator/1]
    }

    Validator.validate(data, schema)
  end

  defp custom_email_validator(value) do
    if String.contains?(value, "@") do
      :ok
    else
      {:error, "Invalid email format"}
    end
  end

  # ... rest of the pipeline
end
```

### Handling Validation Errors

The `validate/2` function returns one of the following:

- `{:ok, data}` if all validations pass.
- `{:error, field, reason}` if a validation fails.

In your pipeline, you can handle these results accordingly:

```elixir
def validate_extract(data) do
  schema = %{
    name: [&Validator.required/1, &Validator.type(String)],
    age: [&Validator.type(Integer)],
    email: [&Validator.required/1, &custom_email_validator/1]
  }

  case Validator.validate(data, schema) do
    {:ok, validated_data} ->
      {:ok, validated_data}
    {:error, field, reason} ->
      {:error, "Validation failed for #{field}: #{reason}"}
  end
end
```

This validation system allows you to ensure data integrity at each step of your ETL process, catching and handling errors early in the pipeline.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.