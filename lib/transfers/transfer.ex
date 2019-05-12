defmodule FS.Transfert do
  @moduledoc """
  Transfert client/server

  """

  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # @doc """
  # Get all references of currencies
  # """
  # @spec get_all_code(GenServer.server()) :: term()
  # def get_all_code(server) do
  #   GenServer.call(server, :get_all_code)
  # end

  @doc """
  Get one reference from the `number code` like "978" or `name code` like "EUR".
  """
  @spec get_one_code(GenServer.server(), integer() | String.t()) :: term()
  def get_one_code(server, code_ref) do
    GenServer.call(server, {:get_one_code, code_ref})
  end

  ## Server Callbacks

  @doc """
  Init the state of the Server

  ##### iso_ref
  iso_ref = [%{},]
  Provide all informations about currencies

  Where:
  "Entity": "COUNTRY NAME",
  "Currency": "Currency name",
  "Alphabetic Code": "Alphabetic Code",
  "Numeric Code": "Numeric Code",
  "Minor unit": "Number of digit after the decimal separator",

  Exemple:
  ```
  [{
  "Entity": "AFGHANISTAN",
  "Currency": "Afghani",
  "Alphabetic Code": "AFN",
  "Numeric Code": "971",
  "Minor unit": "2"
  }]
  ```

  ##### last_conversions
  Backup solutions, if the API is not available.
  The file `last_conversions.json` si re-write each time an update is available.
  Check by timestamp.

  If this backup solution is used and the datas are too late, an advertissement :error should is
  provide

  ##### available_currencies
  available_currencies = [{"numeric_code", "alpha_code"}]

  Return a list of tuple of [{numeric name, alphabetic name}]

  Reference the compliant currencies from Fixer.io with the ISO 42_17.
  Only these currencies will be available in found transferts.

  Return {:ok, {iso_ref, last_conversions, available_currencies}}
  """
  def init(:ok) do
    iso_ref = Currency_API.get_iso_ref()
    last_conversions = Currency_API.get_last_conversions()
    available_currencies = Currency_API.get_available_currencies(iso_ref, last_conversions)
    {:ok, {iso_ref, last_conversions, available_currencies}}
  end

  # def handle_call(:get_all_code, _from, {iso_ref, last_conversions, available_currencies}) do
  #   if is_list(iso_ref) do
  #     IO.inspect(iso_ref, limit: :infinity)
  #   end
  #
  #   # new_iso_ref = Currency_API.get_all_json("conversions.json")
  #   {:reply, iso_ref, {iso_ref, last_conversions, available_currencies}}
  # end

  def handle_call({:get_one_code, code}, _from, {iso_ref, last_conversions, available_currencies}) do
    case Enum.find(available_currencies, fn {num, name, _minor_unit} ->
           num == code || name == code
         end) do
      {alpha_code, numeric_code, minor_unit} ->
        {:reply, {alpha_code, numeric_code, minor_unit},
         {iso_ref, last_conversions, available_currencies}}

      _ ->
        {:reply, {:error, "Currency unavailable"},
         {iso_ref, last_conversions, available_currencies}}
    end
  end

  # def handle_call({:get_one_ref, code_ref}, _from, {iso_ref}) do
  #   if is_integer?(code_ref) do
  #     Enum.find(iso_ref, fn %{} -> Map.get() == id end)
  #     |> IO.inspect()
  #   else
  #     Enum.filter(iso_ref, fn {key, _value} -> key == id end)
  #     |> IO.inspect()
  #   end
  # end
end
