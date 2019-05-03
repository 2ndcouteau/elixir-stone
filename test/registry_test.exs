defmodule FS.RegistryTest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Registry)
    %{registry: registry}
  end

  test "spawns client", %{registry: registry} do
    assert FS.Registry.lookup(registry, "Client1") == :error

    FS.Registry.create(registry, "Client2")
    assert {:ok, client2} = FS.Registry.lookup(registry, "Client2")

    FS.Clients.put(client2, "name", "Jorge")
    assert FS.Clients.get(client2, "name") == "Jorge"
  end
end
