defmodule KVTest do
  use ExUnit.Case
  doctest KV

  test "greets the world" do
    assert KV.hello() == :world
  end

  test "Oops" do
    assert KV.hello() != :oops
  end
end
