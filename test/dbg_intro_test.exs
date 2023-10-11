defmodule DbgIntroTest do
  use ExUnit.Case
  doctest DbgIntro

  test "greets the world" do
    assert DbgIntro.hello() == :world
  end
end
