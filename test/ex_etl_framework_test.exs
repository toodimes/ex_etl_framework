defmodule ExEtlFrameworkTest do
  use ExUnit.Case
  doctest ExEtlFramework

  test "greets the world" do
    assert ExEtlFramework.hello() == :world
  end
end
