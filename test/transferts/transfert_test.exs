defmodule FS.TransferTest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Transfer)
    %{registry: registry}
  end

  # test "Get all currency codes couple", %{registry: registry} do
  #   assert FS.Transfert.get_all_code(registry)
  # end
  #
  test "Get one currency code couple", %{registry: registry} do
    assert FS.Transfer.get_one_code(registry, "USD") == {"840", "USD", "2"}
    assert FS.Transfer.get_one_code(registry, "840") == {"840", "USD", "2"}
    assert FS.Transfer.get_one_code(registry, "000") == {:error, "Currency unavailable"}
  end
end
