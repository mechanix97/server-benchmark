defmodule ElixirSvTest do
  use ExUnit.Case
  doctest ElixirSv

  test "greets the world" do
    assert ElixirSv.hello() == :world
  end
end
