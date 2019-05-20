defmodule FS.TransferTest do
  use ExUnit.Case
  use DecimalArithmetic

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
    assert {client_pid3, id3} = FS.create_client("tata", 978, 105_252.00)

    # Simple transfer
    assert FS.Transfer.transfer(id1, id2, 986, 4242, true) == [:ok]
    assert FS.Clients.get_one_wallet_infos(id1, "986") == {"986", ~m(0.00)}
    assert FS.Clients.get_one_wallet_infos(id2, "986") == {"986", ~m(105252.00)}

    # No direct conversion
    assert FS.Transfer.transfer(id3, id1, 978, 4242, false) == [:ok]
    # Check main_currency wallet
    assert FS.Clients.get_one_wallet_infos(id1, "986") == {"986", ~m(0.00)}
    # Check new currency wallet
    assert {currency, value} = FS.Clients.get_one_wallet_infos(id1, "978")
    assert currency == "978"
    assert Decimal.cmp(value, 0) == :gt
    # Check debit from id3 wallet
    assert FS.Clients.get_one_wallet_infos(id3, "978") == {"978", ~m(101010.00)}

    # Unknown wallet
    assert FS.Clients.get_one_wallet_infos(id3, "986") == nil

    # Not enough founds
    assert FS.Transfer.transfer(id1, id2, 986, 4242, true) == :error

    # Unknown client ID
    assert FS.Transfer.transfer(6000, id2, 986, 4242, true) == :error
    assert FS.Transfer.transfer(id1, 8000, 986, 4242, true) == :error

    # No value transfered
    assert FS.Transfer.transfer(id1, id2, 986, 0, true) == :error

    # Negative value transfer
    assert FS.Transfer.transfer(id1, id2, 986, -4242, true) == :error

    # Bad currency
    assert FS.Transfer.transfer(id1, id2, 123, 4242, true) == :error
    assert FS.Transfer.transfer(id1, id2, "ABC", 4242, true) == :error

    assert FS.delete_client(id1)
    assert FS.delete_client(id2)
    assert FS.delete_client(id3)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Transfer/3 ", %{registry: _registry} do
    assert {client_pid1, id1} = FS.create_client("toto", 986, 4242)
    assert {client_pid2, id2} = FS.create_client("titi", 986, 101_010)
    assert {client_pid3, id3} = FS.create_client("tata", 978, 105_252.00)

    ## Valid Tests

    # Different clients, same currency
    assert FS.Transfer.transfer(id1 + 986, id2 + 986, 4242) == [:ok]

    # Different clients, different currency
    assert FS.Transfer.transfer(id3 + 978, id1 + 986, 4242) != :error

    # Same client, same currency
    assert FS.Transfer.transfer(id1 + 986, id1 + 986, 4242) == [:ok]

    # Same client, different currency
    assert FS.Transfer.transfer(id1 + 986, id1 + 978, 4242) != :error

    ## Error Tests

    # Invalid transfer amount
    assert FS.Transfer.transfer(id1 + 986, id2 + 986, 0) == :error
    assert FS.Transfer.transfer(id1 + 986, id2 + 986, -4242) == :error

    # Unknown client
    assert FS.Transfer.transfer(8000 + 986, id2 + 986, 4242) == :error
    assert FS.Transfer.transfer(id1 + 986, 9000 + 986, 4242) == :error

    # Unknown currency
    assert FS.Transfer.transfer(id1 + 123, id2 + 986, 4242) == :error
    assert FS.Transfer.transfer(id1 + 986, id2 + 123, 4242) == :error

    assert FS.delete_client(id1)
    assert FS.delete_client(id2)
    assert FS.delete_client(id3)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Transfer/4 ", %{registry: _registry} do
    assert {client_pid1, id1} = FS.create_client("toto", 986, 4242)

    ## Valid Tests

    # Diferent currency
    assert FS.Transfer.transfer(id1, 986, 124, 4242) != :error

    assert FS.Transfer.transfer(id1, 124, 986, 424) != :error

    # Same currency
    assert FS.Transfer.transfer(id1, 124, 124, 200) == [:ok]

    # With named currency
    assert FS.Transfer.transfer(id1, "BRL", 124, 42) != :error

    assert FS.Transfer.transfer(id1, 124, "EUR", 42) != :error

    ## Error Tests

    # Bad currency
    assert FS.Transfer.transfer(id1, 123, 124, 20) == :error
    assert FS.Transfer.transfer(id1, 124, 123, 20) == :error

    assert FS.Transfer.transfer(id1, "ABC", 124, 200) == :error
    assert FS.Transfer.transfer(id1, 124, "ABC", 200) == :error

    # Bad amount
    assert FS.Transfer.transfer(id1, 124, 124, -200) == :error
    assert FS.Transfer.transfer(id1, 124, 124, 9200) == :error

    # Unknown client
    assert FS.Transfer.transfer(8000, 124, 124, 200) == :error

    assert FS.delete_client(id1)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Multi_Transfer/5 ", %{registry: _registry} do
    assert {client_pid1, id1} = FS.create_client("toto", 986, 4242)
    assert {client_pid2, id2} = FS.create_client("titi", 986, 101_010)
    assert {client_pid3, id3} = FS.create_client("tata", 978, 105_252.00)
    assert {client_pid2, id4} = FS.create_client("tutu", 986, 101_010)

    # Simple transfer
    assert FS.Transfer.multi_transfer(id1, [id2, id3, id4], 986, 4242, true) == [:ok, :ok, :ok]
    assert FS.Clients.get_one_wallet_infos(id1, "986") == {"986", ~m(0.00)}

    # No direct conversion
    assert FS.Transfer.multi_transfer(id3, [id1, id2, id4], 978, 1000, false) == [:ok, :ok, :ok]
    # Check main_currency wallet
    assert FS.Clients.get_one_wallet_infos(id1, "986") == {"986", ~m(0.00)}
    # Check new currency wallet
    assert {currency, value} = FS.Clients.get_one_wallet_infos(id1, "978")
    assert currency == "978"
    assert Decimal.cmp(value, 0) == :gt

    # Check debit from id3 wallet
    assert FS.Clients.get_one_wallet_infos(id3, "978") != nil

    # Unknown wallet
    assert FS.Clients.get_one_wallet_infos(id3, "986") == nil

    # Not enough founds
    assert FS.Transfer.multi_transfer(id1, [id2], 986, 4242, true) == :error

    # Unknown client ID
    assert FS.Transfer.multi_transfer(46000, [id1, id2, id3], 986, 4242, true) == :error
    assert FS.Transfer.multi_transfer(id1, [id2, 8000, id3, id4], 986, 4242, true) == :error

    # No value transfered
    assert FS.Transfer.multi_transfer(id1, [id2, id3, id4], 986, 0, true) == :error

    # Negative value transfer
    assert FS.Transfer.multi_transfer(id1, [id2, id3, id4], 986, -4242, true) == :error

    # Bad currency
    assert FS.Transfer.multi_transfer(id1, [id2, id3, id4], 123, 4242, true) == :error
    assert FS.Transfer.multi_transfer(id1, [id2, id3, id4], "ABC", 4242, true) == :error

    assert FS.delete_client(id1)
    assert FS.delete_client(id2)
    assert FS.delete_client(id3)
    assert FS.delete_client(id4)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end

  test "Multi_transfer/3 ", %{registry: _registry} do
    assert {client_pid1, id1} = FS.create_client("toto", 986, 4242)
    assert {client_pid2, id2} = FS.create_client("titi", 986, 101_010)
    assert {client_pid3, id3} = FS.create_client("tata", 978, 105_252.00)

    ## Valid Tests

    # Different clients, same currency
    assert FS.Transfer.multi_transfer(id1 + 986, [id2 + 986, id3 + 986], 4242) == [:ok, :ok]

    # Different clients, different currency
    assert FS.Transfer.multi_transfer(id3 + 978, [id1 + 986, id2 + 124], 4242) == [:ok, :ok]

    # Same client, same currency
    assert FS.Transfer.multi_transfer(id1 + 986, [id1 + 986, id1 + 986], 1000) == [:ok, :ok]

    # Same client, different currency
    assert FS.Transfer.multi_transfer(id1 + 986, [id1 + 978, id1 + 124], 100) == [:ok, :ok]

    ## Error Tests

    # Invalid transfer amount
    assert FS.Transfer.multi_transfer(id1 + 986, [id2 + 986, id3 + 978], 0) == :error
    assert FS.Transfer.multi_transfer(id1 + 986, [id2 + 986, id3 + 978], -4242) == :error

    # Unknown client
    assert FS.Transfer.multi_transfer(8000 + 986, [id2 + 986, id3 + 978], 4242) == :error

    assert FS.Transfer.multi_transfer(id1 + 986, [9000 + 986, id2 + 986, 12000 + 124], 4242) ==
             :error

    # Unknown currency
    assert FS.Transfer.multi_transfer(id1 + 123, [id2 + 986, id3 + 978], 4242) == :error

    assert FS.Transfer.multi_transfer(id1 + 986, [id2 + 123, id3 + 124, id1 + 321], 4242) ==
             :error

    assert FS.delete_client(id1)
    assert FS.delete_client(id2)
    assert FS.delete_client(id3)
    Supervisor.terminate_child(FS.Supervisor, Register)
  end
end
