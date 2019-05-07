defmodule FS.RegistryTest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Registry)
    %{registry: registry}
  end

  test "spawns client", %{registry: registry} do
    assert {client_pid, id} = FS.Registry.create_client(registry, "Toto")

    assert is_pid(client_pid) == true
    assert is_integer(id) == true
    assert Integer.mod(id, 1000) == 0
  end

  test "Fetch info client by ID", %{registry: registry} do
    {_, id} = FS.Registry.create_client(registry, "Toto")

    assert list = FS.Registry.fetch(registry, id)

    assert {:ok, {client_pid, id, name}} = Enum.fetch(list, 0)
    assert is_pid(client_pid) == true
    assert is_integer(id) == true
    assert Integer.mod(id, 1000) == 0
    assert name == "Toto"
  end

  test "Fetch info client by Name", %{registry: registry} do
    FS.Registry.create_client(registry, "Toto")

    assert list = FS.Registry.fetch(registry, "Toto")

    assert {:ok, {client_pid, id, name}} = Enum.fetch(list, 0)
    assert is_pid(client_pid) == true
    assert is_integer(id) == true
    assert Integer.mod(id, 1000) == 0
    assert name == "Toto"
  end

  test "Fetch info of Multi same named clients by Name", %{registry: registry} do
    FS.Registry.create_client(registry, "Toto")
    FS.Registry.create_client(registry, "Toto")
    FS.Registry.create_client(registry, "Toto")

    assert list = FS.Registry.fetch(registry, "Toto")

    assert {:ok, {client_pid, id, name}} = Enum.fetch(list, 0)
    assert is_pid(client_pid) == true
    assert is_integer(id) == true
    assert Integer.mod(id, 1000) == 0
    assert name == "Toto"

    assert {:ok, {client_pid, id, name}} = Enum.fetch(list, 1)
    assert is_pid(client_pid) == true
    assert is_integer(id) == true
    assert Integer.mod(id, 1000) == 0
    assert name == "Toto"

    assert {:ok, {client_pid, id, name}} = Enum.fetch(list, 2)
    assert is_pid(client_pid) == true
    assert is_integer(id) == true
    assert Integer.mod(id, 1000) == 0
    assert name == "Toto"
  end
end
