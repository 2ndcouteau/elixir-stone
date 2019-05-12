defmodule Currency_API do
  @moduledoc """
  All about currencies.
  Management functions for the currency API.
  Let us get "Real time values" of the current currencies.

  note: get @api_key from the `FS.Fixer_API`
  """
  use FS.Fixer_API

  @type p_decode :: nil | true | false | list() | float() | integer() | String.t() | map()
  @type currency :: integer() | String.t()

  @spec get_exchange_rates() :: any()
  def get_exchange_rates() do
    url = "http://data.fixer.io/api/latest?access_key=#{@key_api}"

    response = HTTPoison.get!(url)
    req = Poison.decode!(response.body)
    req
  end

  @doc """
  Update the rescue file of conversion rate.
  The file is in "lib/transfers/resources/last_conversions.json"

  It's use when the Fixer.io API is not available.
  This file is updated when the timestamp is updated, each hour for free account.
  """
  @spec update_rescue_conversion_rates(String.t()) :: {atom()}
  def update_rescue_conversion_rates(new_rates) do
    case IO.write("lib/transfers/resources/last_conversions.json", new_rates) do
      {:ok} ->
        {:ok}

      {:error, reason} ->
        IO.warn(reason)
        {:error}
    end
  end

  @doc """
  Get the last conversions rates informations from the `rescue` file.

  In the normal process, these informations are fetch directly on the `fixer.io` API.
  """
  @spec get_last_conversions :: p_decode()
  def get_last_conversions() do
    last_conversions = get_all_json("lib/transfers/resources/last_conversions.json")
    last_conversions
  end

  @doc """
  Get the informations of the ISO_4217 reference file.

  This document list information for each country as following:
  ```
  "Entity": "AFGHANISTAN",
  "Currency": "Afghani",
  "Alphabetic Code": "AFN",
  "Numeric Code": "971",
  "Minor unit": "2"
  ```
  """
  @spec get_iso_ref() :: p_decode()
  def get_iso_ref() do
    if File.exists?("lib/transfers/resources/ISO_4217_reference.json") do
      iso_ref = get_all_json("lib/transfers/resources/ISO_4217_reference.json")
      iso_ref
    end
  end

  @doc """
  Reference the compliant currencies from Fixer.io with the ISO 42_17
  Only this currencies will be available in transfert found

  Return a list of tuple of [{numeric name, alphabetic name}]
  """
  @spec get_available_currencies([tuple()], map()) :: [any()]
  def get_available_currencies(iso_ref, last_conversions) do
    # available_currencies = Currency_API.get_all_json("lib/transferts/resources/common_list_name_code.json")
    last_conversions_names =
      Map.get(last_conversions, "rates")
      |> Map.keys()
      |> Enum.sort()

    # |> IO.inspect(label: "last_conv", limit: :infinity)

    iso_ref_names =
      Enum.map(iso_ref, fn map ->
        {Map.get(map, "Numeric Code"), Map.get(map, "Alphabetic Code"),
         Map.get(map, "Minor unit")}
      end)
      |> Enum.sort()
      |> Enum.uniq()

    # |> IO.inspect(label: "iso_ref", limit: :infinity)

    available_currencies =
      Enum.filter(iso_ref_names, fn {_num, name, _unit} ->
        Enum.member?(last_conversions_names, name)
      end)
      |> Enum.sort()

    # |> IO.inspect(label: "available_currencies", limit: :infinity)

    available_currencies
  end

  @doc """
  Read and return a json file in an usable format.
  """
  @spec get_all_json(String.t()) :: p_decode
  def get_all_json(path_file) do
    case File.read(path_file) do
      {:ok, content} ->
        Poison.decode!(content)

      {:error, reason} ->
        IO.warn(reason)
    end
  end

  @doc """
  ## Conversion

  Make conversion between two currencies.
  Base : EUR

  This conversion takes into account the numbers the `minor number` of each currencies.
  The default context has a precision of 28, the rounding algorithm is :half_up.
  The set trap enablers are :invalid_operation and :division_by_zero
  """
  @spec conversion(integer(), currency, currency) :: any()
  def conversion(value, from_currency, to_currency) do
    base = FS.Transfer.get_base(Transfer)

    case is_bases?(base, from_currency, to_currency) do
      {false, false} ->
        {:error, :no_conversion}

      {false, true} ->
        currency_to_base(value, from_currency)
        |> round_minor(base)

      {true, false} ->
        base_to_currency(value, to_currency)
        |> round_minor(to_currency)

      {true, true} ->
        currency_to_base(value, from_currency)
        |> base_to_currency(to_currency)
        |> round_minor(to_currency)
    end
  end

  defp round_minor(value, currency) do
    minor_unit = FS.Transfer.get_minor_unit(Transfer, currency)
    Decimal.round(value, minor_unit)
  end

  defp base_to_currency(value, to_currency) do
    value * get_rate(to_currency)
  end

  defp currency_to_base(value, from_currency) do
    value / get_rate(from_currency)
  end

  defp is_bases?(base, currency_code1, currency_code2) do
    if currency_code1 == base do
      if currency_code2 == base do
        {true, true}
      else
        {true, false}
      end
    else
      if currency_code2 == base do
        {false, true}
      else
        {false, false}
      end
    end
  end

  @doc """
  Return the current rate for the currency.

  If the currency does not exist, return `{:error, "Currency unavailable"}`.
  """
  @spec get_rate(String.t() | integer()) :: float() | {:error, String.t()}
  def get_rate(currency_code) do
    FS.Transfer.get_one_rate(Transfer, currency_code)
  end
end
