defmodule FS.TransferTest do
  use ExUnit.Case

  setup do
    registry = start_supervised!(FS.Transfer)
    %{registry: registry}
  end

  test "Get one currency code couple", %{registry: registry} do
    assert FS.Transfer.get_one_code(registry, "USD") == {"840", "USD", "2"}
    assert FS.Transfer.get_one_code(registry, "840") == {"840", "USD", "2"}
    assert FS.Transfer.get_one_code(registry, "000") == {:error, "Currency unavailable"}
  end

  test "Get currency infos", %{registry: registry} do
    available_currencies = FS.Transfer.get_available_currencies(registry)

    assert FS.Transfer.get_currency_infos("USD", available_currencies) == {"840", "USD", "2"}
    assert FS.Transfer.get_currency_infos("840", available_currencies) == {"840", "USD", "2"}
    assert FS.Transfer.get_currency_infos("ABC", available_currencies) == nil
    assert FS.Transfer.get_currency_infos("000", available_currencies) == nil
  end

  test "Get one code", %{registry: registry} do
    assert FS.Transfer.get_one_code(registry, "840") == {"840", "USD", "2"}
    assert FS.Transfer.get_one_code(registry, 840) == {"840", "USD", "2"}
    assert FS.Transfer.get_one_code(registry, "USD") == {"840", "USD", "2"}
    assert FS.Transfer.get_one_code(registry, "EUR") == {"978", "EUR", "2"}
    assert FS.Transfer.get_one_code(registry, "978") == {"978", "EUR", "2"}

    assert FS.Transfer.get_one_code(registry, "123") == {:error, "Currency unavailable"}
    assert FS.Transfer.get_one_code(registry, "ABC") == {:error, "Currency unavailable"}

    assert FS.Transfer.get_one_code(registry, :USD) == {:error, "Currency unavailable"}
  end

  test "Get one rate from last_conversions state", %{registry: registry} do
    last_conversions = FS.Transfer.get_last_conversions(registry)

    assert FS.Transfer.get_one_rate(registry, "BOB") ==
             Map.get(last_conversions, "rates")
             |> Map.get("BOB")

    assert FS.Transfer.get_one_rate(registry, "068") ==
             Map.get(last_conversions, "rates")
             |> Map.get("BOB")
  end

  # Direct request to the Fixer.io API
  # !!! Credit limited to 1000 requests by month
  @tag :external
  test "Get one rate from Fixer API", %{registry: registry} do
    last_conversions = Currency_API.get_exchange_rates()

    assert FS.Transfer.get_one_rate(registry, "BOB") ==
             Map.get(last_conversions, "rates")
             |> Map.get("BOB")

    assert FS.Transfer.get_one_rate(registry, "068") ==
             Map.get(last_conversions, "rates")
             |> Map.get("BOB")
  end

  test "Get minor unit", %{registry: registry} do
    assert FS.Transfer.get_minor_unit(registry, "USD") == "2"
    assert FS.Transfer.get_minor_unit(registry, "EUR") == "2"

    assert FS.Transfer.get_minor_unit(registry, "840") == "2"
    assert FS.Transfer.get_minor_unit(registry, "068") == "2"

    assert FS.Transfer.get_minor_unit(registry, "XOF") == "0"
    assert FS.Transfer.get_minor_unit(registry, "952") == "0"

    assert FS.Transfer.get_minor_unit(registry, "123") == {:error, "Currency unavailable"}
    assert FS.Transfer.get_minor_unit(registry, "ABC") == {:error, "Currency unavailable"}
  end

  test "Conversion rates need to be updated ?", %{registry: registry} do
    assert FS.Transfer.conversion_rates_up?(registry) == false
  end

  test "Get base currency for transfer from Fixer.io API", %{registry: registry} do
    assert FS.Transfer.get_base(registry) == "EUR"
  end

  test "Transfer/5 ", %{registry: _registry} do
    assert {client_pid1, id1} = FS.create_client("toto", 986, 4242)
    assert {client_pid2, id2} = FS.create_client("titi", 986, 101_010)

    assert FS.Transfer.transfer(id1, id2, 986, 4242, true) == :ok

    assert FS.delete_client(id1)
    assert FS.delete_client(id2)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end
end
