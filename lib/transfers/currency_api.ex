defmodule Currency_API do
  @moduledoc """
  All about currencies.
  Management functions for the currency API.
  Let us get "Real time values" of the current currencies.

  note: get @api_key from the `FS.Fixer_API`
  """
  use FS.Fixer_API

  @type p_decode :: nil | true | false | list() | float() | integer() | String.t() | map()

  @spec get_exchange_rate() :: any()
  def get_exchange_rate() do
    url = "http://data.fixer.io/api/latest?access_key=#{@key_api}"

    response = HTTPoison.get!(url)
    req = Poison.decode!(response.body)
    req
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
    else
      get_exchange_rate()
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
    read_file(path_file)
    |> Poison.decode!()
  end

  defp read_file(path_file) do
    case File.open(path_file) do
      {:ok, file} ->
        # :all can be replaced with :line, or with a positive integer to specify the number of characters to read.
        IO.read(file, :all)

      {:error, reason} ->
        IO.warn(reason)
    end
  end
end
