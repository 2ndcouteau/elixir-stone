defmodule Currency_APITest do
  use ExUnit.Case
  use FS.Path_Resources

  setup do
    registry = start_supervised!(FS.Transfer)
    %{registry: registry}
  end

  # Direct request to the Fixer.io API
  # !!! Credit limited to 1000 requests by month
  @tag :external
  test "Get exchange rates from API", %{registry: _registry} do
    req = Currency_API.get_exchange_rates()

    assert Map.get(req, "success") == true
    assert is_integer(Map.get(req, "timestamp")) == true
    assert Map.get(req, "base") == "EUR"
    assert is_binary(Map.get(req, "date")) == true
    assert is_map(Map.get(req, "rates")) == true
  end

  # Direct request to the Fixer.io API
  # !!! Credit limited to 1000 requests by month
  @tag :external
  test "Update the rescue conversion rates file", %{registry: _registry} do
    req = Currency_API.get_exchange_rates()

    assert Currency_API.update_rescue_conversion_rates(req) == :ok
  end

  # Direct request to the Fixer.io API
  # !!! Credit limited to 1000 requests by month
  @tag :external
  test "Init last conversions", %{registry: _registry} do
    # Read/Write Error
    # Other errors are managed in the same way
    File.chmod(@last_conversions, 0o000)

    assert ExUnit.Assertions.catch_exit(Currency_API.init_last_conversions()) ==
             "Read: last_conversion.json: permission denied"

    File.chmod(@last_conversions, 0o644)

    # File does not exist
    File.rm(@last_conversions)
    assert is_map(Currency_API.init_last_conversions()) == true
    assert File.exists?(@last_conversions) == true

    # Regular File
    assert is_map(Currency_API.init_last_conversions()) == true
  end

  test "Init iso_ref", %{registry: _registry} do
    # Read/Write Error
    # Other errors are managed in the same way
    File.chmod(@iso_ref, 0o000)

    assert ExUnit.Assertions.catch_exit(Currency_API.init_iso_ref()) ==
             "Read: ISO_4217_reference.json: permission denied"

    File.chmod(@iso_ref, 0o644)

    # Regular File
    assert is_list(Currency_API.init_iso_ref()) == true
  end

  test "Init available currencies", %{registry: registry} do
    iso_ref = FS.Transfer.get_iso_ref(registry)
    last_conversions = FS.Transfer.get_last_conversions(registry)

    assert is_list(Currency_API.init_available_currencies(iso_ref, last_conversions)) == true
  end

  test "Number of available currencies", %{registry: registry} do
    assert iso_ref = FS.Transfer.get_iso_ref(registry)
    assert last_conversions = FS.Transfer.get_last_conversions(registry)

    assert available_currencies =
             Currency_API.init_available_currencies(iso_ref, last_conversions)

    assert length(available_currencies) == 154
  end

  test "Get all Json", %{registry: _registry} do
    assert is_list(Currency_API.get_all_json(@iso_ref)) == true

    assert Currency_API.get_all_json("Bad/Path") == {:error, :enoent}
  end

  test "Conversion currencies", %{registry: _registry} do
    # Integer values
    assert Currency_API.conversion(100, "EUR", "USD")
    assert Currency_API.conversion(100, 978, 840)
    assert Currency_API.conversion(100, "EUR", 840)
    assert Currency_API.conversion(100, 978, "USD")

    # Float values
    assert Currency_API.conversion(100.0, "EUR", "USD")
    assert Currency_API.conversion(100.0, 978, 840)
    assert Currency_API.conversion(100.0, "EUR", 840)
    assert Currency_API.conversion(100.0, 978, "USD")
  end
end
