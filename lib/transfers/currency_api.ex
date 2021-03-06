defmodule Currency_API do
  @moduledoc """
  All about currencies.
  Management functions for the currency API.
  Let us get "Real time values" of the current currencies.

  ##### Notes:
    - get @api_key from the `FS.Fixer_API`
    - Paths come from `FS.Path_Resources`
  """
  use FS.Fixer_API
  use FS.Path_Resources

  alias Decimal, as: D

  @type p_decode :: nil | true | false | list() | float() | integer() | String.t() | map()
  @type currency :: integer() | String.t()

  @spec get_exchange_rates() :: map()
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
  @spec update_rescue_conversion_rates(p_decode() | {atom(), atom()}) :: p_decode() | no_return()
  def update_rescue_conversion_rates(last_conversions \\ {:error, :enoent}) do
    response = get_exchange_rates()

    case Map.get(response, "success") do
      true ->
        {_, content} = Poison.encode(response)

        case File.write(@last_conversions, content) do
          :ok ->
            response

          {:error, reason} ->
            :file.format_error(reason)
            |> List.to_string()
            |> (&("Write: last_conversion.json: " <> &1)).()
            |> exit()
        end

      false ->
        Tools.eputs("Update last_conversions impossible.
    Please check the @key_api validity.")

        case last_conversions do
          {:error, reason} ->
            :file.format_error(reason)
            |> List.to_string()
            |> (&("Fetch: last_conversion.json: " <> &1)).()
            |> exit()

          _ ->
            last_conversions
        end
    end
  end

  @doc """
  Get the last conversions rates informations.

  Check if information in rescue file are less than 1 hour old.
  If true, take these informations.

  Else make a request to the API for fresh information.
  If it's failed, take informations from the rescue file
  """
  @spec init_last_conversions :: p_decode
  def(init_last_conversions()) do
    last_conversions = get_all_json(@last_conversions)

    # If the file exists and is valid
    if is_map(last_conversions) do
      # if last_conversions is 1 hour old or more
      case Map.get(last_conversions, "timestamp") < System.os_time() / 1_000_000_000 - 3600 do
        false ->
          last_conversions

        true ->
          update_rescue_conversion_rates(last_conversions)
      end
    else
      case last_conversions do
        # The file does not exist
        {:error, :enoent} ->
          update_rescue_conversion_rates()

        # Other problem with the file
        {:error, reason} ->
          :file.format_error(reason)
          |> List.to_string()
          |> (&("Read: last_conversion.json: " <> &1)).()
          |> exit()
      end
    end
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
  @spec init_iso_ref() :: p_decode()
  def init_iso_ref() do
    iso_ref = get_all_json(@iso_ref)

    case iso_ref do
      {:error, reason} ->
        :file.format_error(reason)
        |> List.to_string()
        |> (&("Read: ISO_4217_reference.json: " <> &1)).()
        |> exit()

      _ ->
        iso_ref
    end
  end

  @doc """
  Reference the compliant currencies from Fixer.io with the ISO 42_17
  Only this currencies will be available in transfert found

  Return a list of tuple of [{numeric name, alphabetic name}]
  """
  @spec init_available_currencies([tuple()], map()) :: [any()]
  def init_available_currencies(iso_ref, last_conversions) do
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
  @spec get_all_json(String.t()) :: p_decode | {atom(), atom()}
  def get_all_json(path_file) do
    case File.read(path_file) do
      {:ok, content} ->
        Poison.decode!(content)

      {:error, reason} ->
        # IO.warn(reason)
        {:error, reason}
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
  @spec conversion(number() | D.t(), currency(), currency()) :: any()
  def conversion(value, from_currency, to_currency) do
    # when is_binary(from_currency)
    # when is_binary(to_currency) do
    # IO.inspect(from_currency, label: "From_currency")
    # IO.inspect(to_currency, label: "To_currency")
    {from_currency, _alpha, _minor} = FS.Transfer.get_one_code(Transfer, from_currency)
    {to_currency, _alpha, _minor} = FS.Transfer.get_one_code(Transfer, to_currency)

    {numeric_base, _alpha_base, _minor_unit} =
      FS.Transfer.get_base(Transfer)
      |> (&FS.Transfer.get_one_code(Transfer, &1)).()

    # |> IO.inspect(label: "BASE")

    dec_value = Tools.type_dec(value)
    # |> IO.inspect(label: "dec_value")

    case is_bases?(numeric_base, from_currency, to_currency) do
      {true, true} ->
        dec_value

      # |> IO.inspect(label: "Conversion TT")

      {false, true} ->
        currency_to_base(dec_value, from_currency)
        |> round_minor(numeric_base)

      # |> IO.inspect(label: "Conversion TF")

      {true, false} ->
        base_to_currency(dec_value, to_currency)
        |> round_minor(to_currency)

      # |> IO.inspect(label: "Conversion FT")

      {false, false} ->
        currency_to_base(dec_value, from_currency)
        |> base_to_currency(to_currency)
        |> round_minor(to_currency)

        # |> IO.inspect(label: "Conversion FF")
    end
  end

  defp round_minor(value, currency) do
    minor_unit = FS.Transfer.get_minor_unit(Transfer, currency)

    case is_binary(minor_unit) do
      true ->
        minor = String.to_integer(minor_unit)
        D.round(value, minor)

      false ->
        {:error, "Currency unavailable"}
    end
  end

  defp base_to_currency(value, to_currency) do
    # IO.inspect(to_currency, label: "ERROR currency")

    get_rate(to_currency)
    |> Tools.type_dec()
    |> (&D.mult(value, &1)).()

    # |> IO.inspect(label: "BtoC")
  end

  defp currency_to_base(value, from_currency) do
    get_rate(from_currency)
    |> Tools.type_dec()
    |> (&D.div(value, &1)).()

    # |> IO.inspect(label: "CtoB")
  end

  defp is_bases?(base, currency_code1, currency_code2) do
    # IO.inspect(base, label: "Base check")
    # IO.inspect(currency_code1, label: "currency1 check")
    # IO.inspect(currency_code2, label: "currency2 check")

    if currency_code1 == base or currency_code1 == currency_code2 do
      if currency_code2 == base or currency_code1 == currency_code2 do
        # IO.inspect("TT")
        {true, true}
      else
        # IO.inspect("TF")
        {true, false}
      end
    else
      if currency_code2 == base do
        # IO.inspect("FT")
        {false, true}
      else
        # IO.inspect("FF")
        {false, false}
      end
    end
  end

  @doc """
  Return the current rate for the currency.

  If the currency does not exist, return `{:error, "Currency unavailable"}`.
  """
  @spec get_rate(String.t() | integer()) :: D.t() | {:error, String.t()}
  def get_rate(currency_code) do
    case FS.Transfer.get_one_rate(Transfer, currency_code) do
      {:error, "Currency unavailable"} ->
        {:error, "Currency unavailable"}

      rate ->
        # IO.inspect(Tools.typeof(rate), label: "Rate_type")
        # IO.inspect(rate, label: "RATE")
        D.from_float(rate)
    end
  end
end
