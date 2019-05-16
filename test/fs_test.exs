defmodule FSTest do
  use ExUnit.Case
  use DecimalArithmetic

  # alias DecimalArithmetic, as: DA

  setup do
    registry = start_supervised!(FS.Registry)
    %{registry: registry}
  end

  test "Create Client with name", %{registry: _registry} do
    assert FS.Registry.fetch(Register, "toto") == []

    assert {client_pid, id} = FS.create_client("toto", 986, 4242)

    assert FS.Clients.get(client_pid, :name) == "toto"
    assert FS.Clients.get(client_pid, :id) == id
    assert FS.Clients.get(client_pid, :main_currency) == "986"
    assert FS.Clients.get(client_pid, :wallets) == %{"986" => ~m(4242.00)}
    assert FS.delete_client(id)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Delete client account", %{registry: _registry} do
    assert {client_pid, id} = FS.create_client("toto")

    assert FS.Registry.fetch(Register, id) != []
    assert FS.delete_client(id)
    assert FS.Registry.fetch(Register, id) == []
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Create New wallet", %{registry: _registry} do
    assert {client_pid, id} = FS.create_client("toto")
    assert FS.Clients.get(client_pid, :wallets) == %{"978" => ~m(0.00)}
    assert {id, currency, amount_deposited} = FS.create_wallet(id, 986, 1234)

    assert FS.Clients.get(client_pid, :wallets)
           |> Map.get("986") == ~m(1234)

    assert {id, currency, amount_deposited} = FS.create_wallet(id, 840, 1234.56)

    assert FS.Clients.get(client_pid, :wallets)
           |> Map.get("840") == ~m(1234.56)

    assert FS.delete_client(id)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Delete wallet", %{registry: _registry} do
    assert {client_pid, id} = FS.create_client("toto")
    assert FS.Clients.get(client_pid, :wallets) == %{"978" => ~m(0.00)}
    assert {id, currency, amount_deposited} = FS.create_wallet(id, 986, 1234)

    assert FS.delete_wallet(id, "986") == :not_empty
    assert FS.delete_wallet(id, "978") == :ok
    assert FS.delete_wallet(id, "123") == :not_exist

    assert FS.Clients.get(client_pid, :wallets) == %{"986" => ~m(1234.00)}

    assert FS.delete_client(id)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Print client infos", %{registry: _registry} do
    assert {client_pid, id} = FS.create_client("toto")

    assert FS.print_client_infos("toto") == :ok
    assert FS.print_client_infos(id) == :ok

    assert FS.delete_client(id)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end
end
