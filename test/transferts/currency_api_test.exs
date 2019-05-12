defmodule Currency_APITest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Transfer)
    %{registry: registry}
  end

  test "Get available currencies", %{registry: _registry} do
    assert iso_ref = Currency_API.get_iso_ref()
    assert last_conversions = Currency_API.get_last_conversions()
    assert available_currencies = Currency_API.get_available_currencies(iso_ref, last_conversions)

    assert length(available_currencies) == 154
  end

  # test "Conversion currencies", %{registry: _registry} do
  #   assert Currency_API.conversion(100, "EUR", "USD")
  #   assert Currency_API.conversion(100, 978, 840)
  #   assert Currency_API.conversion(100, "EUR", 840)
  #   assert Currency_API.conversion(100, 978, "USD")
  # end
end
