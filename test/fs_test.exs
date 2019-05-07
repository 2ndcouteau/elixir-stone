defmodule FSTest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Registry)
    %{registry: registry}
  end

  test "Create Client with name", %{registry: registry} do
    assert FS.Registry.fetch(registry, "toto") == []

    assert {client_pid, id} = FS.Registry.create_client(registry, "toto")
    assert FS.Clients.put(client_pid, "toto", id, 986, 4242)

    assert FS.Clients.get(client_pid, :name) == "toto"
    assert FS.Clients.get(client_pid, :id) == id
    assert FS.Clients.get(client_pid, :main_currency) == 986
    # assert FS.Clients.get(client_pid, :wallet) == %{986 => 4242}
  end
end
