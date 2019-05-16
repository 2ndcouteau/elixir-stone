defmodule FS.ClientsTest do
  use ExUnit.Case
  use DecimalArithmetic

  setup do
    registry = start_supervised!(FS.Registry)
    %{registry: registry}
  end

  test "Get one wallet infos", %{registry: _registry} do
    assert {client_pid, id} = FS.create_client("toto", 986, 4242)
    assert FS.Clients.get_one_wallet_infos(id, "986") == {"986", ~m(4242.00)}

    assert FS.delete_client(id)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end
end
