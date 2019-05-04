defmodule FSTest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Registry)
    %{registry: registry}
  end

  test "Create Client", %{registry: _registry} do
    # assert FS.Registry.fetch(registry, "toto") == :error

    {client_pid, id} = FS.cc("toto", "EUR")

    # = FS.Registry.fetch(registry, "toto")

    assert FS.Clients.get(client_pid, :name) == "toto"
    assert FS.Clients.get(client_pid, :id) == id
    assert FS.Clients.get(client_pid, :main_currency) == "EUR"
    #
    # assert {:ok, client} = FS.Registry.lookup(registry, "toto")
    #
  end
end
