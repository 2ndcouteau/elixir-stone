defmodule FSTest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Registry)
    %{registry: registry}
  end

  test "Create Client with name", %{registry: _registry} do
    assert FS.Registry.fetch(Register, "toto") == []

    assert {client_pid, id} = FS.cc("toto", 986, 4242)

    assert FS.Clients.get(client_pid, :name) == "toto"
    assert FS.Clients.get(client_pid, :id) == id
    assert FS.Clients.get(client_pid, :main_currency) == 986
    assert FS.Clients.get(client_pid, :wallet) == {986, 4242}
    Supervisor.restart_child(FS.Supervisor, Register)
  end

  test "Delete client account", %{registry: _registry} do
    assert {client_pid, id} = FS.cc("toto")

    assert FS.Registry.fetch(Register, id) != []
    assert FS.delete_client(id)
    assert FS.Registry.fetch(Register, id) == []
    Supervisor.restart_child(FS.Supervisor, Register)
  end
end
