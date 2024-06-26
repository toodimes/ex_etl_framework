# ExEtlFramework

ExEtlFramework is a powerful and flexible ETL (Extract, Transform, Load) framework built in Elixir. It simplifies the process of creating robust data processing pipelines with built-in support for validation, error handling, and performance monitoring.

## Features

- **Modular Pipeline Structure**: Easy-to-define ETL steps using a simple DSL
- **Flexible Data Validation**: Schema-based validation with built-in and custom validators
- **Error Handling Strategies**: Choose between fail-fast or error collection approaches
- **Telemetry Integration**: Built-in performance measurement and reporting
- **Extensible**: Easy to add custom steps and validators

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

Create a module for your pipeline and use the `ExEtlFramework.Pipeline` macro:

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
    schema = %{
      data: [&ExEtlFramework.Validator.required/1, &ExEtlFramework.Validator.type(List)]
    }
    ExEtlFramework.Validator.validate(data, schema)
  end
end
```

### Running a Pipeline

Execute your pipeline with optional error handling strategy:

```elixir
result = MyPipeline.run(%{initial: "data"}, error_strategy: :collect_errors)
```

## Key Components

### Pipeline

The core module for defining and executing ETL steps. It provides:

- A DSL for defining pipeline steps
- Automatic error handling
- Integration with the validation system

### Validator

A flexible data validation system:

- Define validation schemas with built-in and custom validators
- Easy to use in pipeline steps
- Supports complex data structures

Example of a validation schema:

```elixir
schema = %{
  name: [&ExEtlFramework.Validator.required/1, &ExEtlFramework.Validator.type(String)],
  age: [&ExEtlFramework.Validator.type(Integer)],
  email: [&ExEtlFramework.Validator.required/1, &custom_email_validator/1]
}
```

### Telemetry Integration

Built-in performance monitoring using Telemetry:

- Automatically measures duration of pipeline runs and individual steps
- Tracks errors in pipelines
- Easy to integrate with your preferred monitoring solution

## Advanced Usage

### Custom Validators

Create custom validation functions:

```elixir
def custom_email_validator(value) do
  if String.contains?(value, "@") do
    :ok
  else
    {:error, "Invalid email format"}
  end
end
```

### Error Handling Strategies

Choose between two error handling strategies:

- `:fail_fast`: Stops the pipeline at the first error
- `:collect_errors`: Continues processing and collects all errors

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.