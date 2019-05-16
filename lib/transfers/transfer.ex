defmodule FS.Transfer do
  @moduledoc """
  Transfert client/server

  """

  use GenServer

  alias Decimal, as: D
  ## Private guards

  # defguardp is_account(id) when is_integer(id) and id >= 1000 and rem(id, 1000) != 0
  defguardp is_client(id) when is_integer(id) and rem(id, 1000) == 0 and id >= 1000

  defguardp is_wallet(id)
            when (is_integer(id) and div(id, 1000) == 0 and id > 0 and id < 1000) or
                   (is_binary(id) and byte_size(id) == byte_size("XXX"))

  ## Client API

  @doc """
  Starts the registry.
  """
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Return the `iso_ref` state of FS.Tranfer server.
  """
  @spec get_iso_ref(GenServer.server()) :: list()
  def get_iso_ref(server) do
    GenServer.call(server, {:get_iso_ref})
  end

  @doc """
  Return the `last_conversions` state of FS.Tranfer server.
  """
  @spec get_last_conversions(GenServer.server()) :: list()
  def get_last_conversions(server) do
    GenServer.call(server, {:get_last_conversions})
  end

  @doc """
  Return the `available_currencies` state of FS.Tranfer server.
  """
  @spec get_available_currencies(GenServer.server()) :: list()
  def get_available_currencies(server) do
    GenServer.call(server, {:get_available_currencies})
  end

  @doc """
  Get one reference from the `number code` like "978" or `name code` like "EUR".
  """
  @spec get_one_code(GenServer.server(), integer() | String.t()) :: term()
  def get_one_code(server, code_ref) do
    GenServer.call(server, {:get_one_code, code_ref})
  end

  @doc """
  Get the rate from the `number code` like "978" or `name code` like "EUR"

  If the rates are out_dated, the rates are updated before return the requested rate.
  """
  @spec get_one_rate(GenServer.server(), integer() | String.t()) :: float() | {atom(), String.t()}
  def get_one_rate(server, code_ref) do
    if conversion_rates_up?(server) do
      ## Check error ??
      update_rates(server)
    end

    GenServer.call(server, {:get_one_rate, code_ref})
  end

  @doc """
    Fetch the updated rates and save them in `last_conversions`.
  """
  @spec update_rates(GenServer.server()) :: atom()
  def update_rates(server) do
    GenServer.call(server, {:update_rates})
  end

  @doc """
  Get the minor unit from `iso_ref`

  This number provide number of digits for rounding.

  Exemple :
  ```
  iex> get_minor_unit(Transfer, "EUR")
  > 2
  ```
  """
  @spec get_minor_unit(GenServer.server(), integer() | String.t()) ::
          String.t() | {atom(), String.t()}
  def get_minor_unit(server, currency) do
    GenServer.call(server, {:get_minor_unit, currency})
  end

  @doc """
  Return a Boolean to know if the `last_conversions` are outdated.
  This compare the timestamp in `last_conversion.json` and the `System.os_time()` + 1 hour
  """
  @spec conversion_rates_up?(GenServer.server()) :: bool()
  def conversion_rates_up?(server) do
    GenServer.call(server, {:conversion_rates_up?})
  end

  @doc """
  Return the `base` from the `last_conversions` state elem.
  """
  @spec get_base(GenServer.server()) :: String.t()
  def get_base(server) do
    GenServer.call(server, {:get_base})
  end

  @doc """
  Transfer value from one given currency wallet to another client.

  tranfer/5

  The wallet destination of the client is defined by the `direct_conversion` parameter.
  If the direct conversion is `:true`, the value will be deposited in the main wallet of the client.
  Else, the amount will be deposited in the same currency wallet than the sending client.
  In this case, if the destination client does not already have a compliant currency wallet,
  this last is created.

  Exemple:
  ```
    transfer(42000, 24000, 101010, "BRL", :false)
  ```
  """
  @spec transfer(
          integer(),
          integer(),
          integer() | String.t(),
          number() | D.t(),
          boolean()
        ) :: atom()
  def transfer(client_id, to_client_id, currency, value, direct_conversion)
      when is_client(client_id)
      when is_client(to_client_id)
      when is_wallet(currency)
      when value > 0
      when is_boolean(direct_conversion) do
    value = Tools.type_dec(value)
    currency = Tools.type_currency(currency)
    client = FS.Clients.get_client_back_infos(client_id)
    to_client = FS.Clients.get_client_back_infos(to_client_id)

    case check_transfer_elements(client, client_id, to_client, to_client_id, currency, value) do
      :ok ->
        # make_transfer()
        :ok

      {:error, reason} ->
        Tools.eputs(reason)
    end
  end

  @spec check_transfer_elements(tuple, integer(), tuple(), integer(), String.t(), D.t()) ::
          {atom(), String.t()} | atom()
  def check_transfer_elements(client, client_id, to_client, to_client_id, currency, value) do
    cond do
      client == nil ->
        {:error, "Client #{client_id} does not exist"}

      to_client == nil ->
        {:error, "Client #{to_client_id} does not exist"}

      true ->
        case get_one_code(Transfer, currency) do
          {:error, reason} ->
            {:error, reason}

          {numeric_code, alpha_code, _minor_unit} ->
            case FS.Clients.get_one_wallet_infos(client_id, numeric_code) do
              # account_value = Tools.type_dec(account_value)
              # IO.inspect("VALUE -- #{value}" <> Tools.typeof(value))
              # IO.inspect("Account -- #{account_value}" <> Tools.typeof(account_value))

              {_w_currency, w_value} ->
                case Decimal.cmp(value, w_value) do
                  :lt ->
                    {:error, "Not enough money available. Founds available: #{w_value}"}

                  _ ->
                    :ok
                end

              nil ->
                {:error, "The Client '#{client_id}' does have an #{alpha_code} account."}
            end
        end
    end

    # case get_one_code(currency) do
    #   {numeric_code, alpha_code, minor_unit} ->
    #
    #   {:error, reason} ->
    #     IO.warn(reason)
    # end
  end

  #
  # @doc """
  # Transfer value from one account to another.
  #
  # tranfer/3
  #
  # An account is a partcular wallet of a particular client.
  # The id account is contruct by the addition of the id_client and the id_currency of the wallet
  #
  # Exemple:
  # For the account_id = 45978, the id_client is 45000 and the wallet is 978 => EUR
  # """
  # @spec transfer(integer(), integer(), number() | D.t()) :: atom()
  # def transfer(account_id, to_account_id, value)
  #     when is_account(account_id)
  #     when is_account(to_account_id)
  #     when value > 0 do
  #   value = Tools.type()
  # end
  #
  # @doc """
  # Transfer value from wallet to another wallet for the same Client
  #
  # tranfer/4
  #
  # - wallet/to_wallet :: currency_code :: integer in list_currency ISO_4217
  # """
  # @spec transfer(integer(), integer(), integer(), number() | D.t()) :: atom()
  # def transfer(client_id, wallet, to_wallet, value)
  #     when is_client(client_id)
  #     when is_wallet(wallet)
  #     when is_wallet(to_wallet)
  #     when value > 0 do
  #   value
  # end

  # defmacro is_wallet(id) do
  #     quote do
  #       is_integer(unquote(id)) and div(unquote(id), 1000) == 0 and unquote(id) > 0
  #     end
  #   end
  # end

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
    iso_ref = Currency_API.init_iso_ref()
    last_conversions = Currency_API.init_last_conversions()
    available_currencies = Currency_API.init_available_currencies(iso_ref, last_conversions)
    {:ok, {iso_ref, last_conversions, available_currencies}}
  end

  def handle_call({:get_iso_ref}, _from, {iso_ref, last_conversions, available_currencies}) do
    {:reply, iso_ref, {iso_ref, last_conversions, available_currencies}}
  end

  def handle_call(
        {:get_last_conversions},
        _from,
        {iso_ref, last_conversions, available_currencies}
      ) do
    {:reply, last_conversions, {iso_ref, last_conversions, available_currencies}}
  end

  def handle_call(
        {:get_available_currencies},
        _from,
        {iso_ref, last_conversions, available_currencies}
      ) do
    {:reply, available_currencies, {iso_ref, last_conversions, available_currencies}}
  end

  def handle_call({:get_one_code, code}, _from, {iso_ref, last_conversions, available_currencies}) do
    code = Tools.type_currency(code)

    case Enum.find(available_currencies, fn {num, name, _minor_unit} ->
           num == code || name == code
         end) do
      {numeric_code, alpha_code, minor_unit} ->
        {:reply, {numeric_code, alpha_code, minor_unit},
         {iso_ref, last_conversions, available_currencies}}

      _ ->
        {:reply, {:error, "Currency unavailable"},
         {iso_ref, last_conversions, available_currencies}}
    end
  end

  def handle_call({:get_one_rate, code}, _from, {iso_ref, last_conversions, available_currencies}) do
    case get_currency_infos(code, available_currencies) do
      {_num, name, _minor} ->
        rate =
          Map.get(last_conversions, "rates")
          |> Map.get(name)

        {:reply, rate, {iso_ref, last_conversions, available_currencies}}

      nil ->
        {:reply, {:error, "Currency unavailable"},
         {iso_ref, last_conversions, available_currencies}}
    end
  end

  def handle_call({:get_base}, _from, {iso_ref, last_conversions, available_currencies}) do
    base = Map.get(last_conversions, "base")
    {:reply, base, {iso_ref, last_conversions, available_currencies}}
  end

  def handle_call(
        {:conversion_rates_up?},
        _from,
        {iso_ref, last_conversions, available_currencies}
      ) do
    up? = System.os_time() / 1_000_000_000 - 3600 > Map.get(last_conversions, "timestamp")

    {:reply, up?, {iso_ref, last_conversions, available_currencies}}
  end

  def handle_call({:update_rates}, _from, {iso_ref, last_conversions, available_currencies}) do
    response = Currency_API.get_exchange_rates()

    case Map.get(response, "success") do
      true ->
        Currency_API.update_rescue_conversion_rates(response)
        {:reply, :ok, {iso_ref, response, available_currencies}}

      false ->
        {:reply, :error, {iso_ref, last_conversions, available_currencies}}
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

  def handle_call(
        {:get_minor_unit, currency},
        _from,
        {iso_ref, last_conversions, available_currencies}
      ) do
    case get_currency_infos(currency, available_currencies) do
      {_num, _name, minor} ->
        minor_unit = minor
        {:reply, minor_unit, {iso_ref, last_conversions, available_currencies}}

      nil ->
        {:reply, {:error, "Currency unavailable"},
         {iso_ref, last_conversions, available_currencies}}
    end
  end

  def get_currency_infos(code, available_currencies) do
    code =
      with true <- is_integer(code) do
        Integer.to_string(code)
      else
        false ->
          code
      end

    Enum.find(available_currencies, nil, fn {num, name, _minor} ->
      code == num || code == name
    end)
  end

  # @doc """
  # Get the list of all country using this currency
  # Return all available informations in iso_ref
  # """
  # get_all_currency_infos(code, iso_ref) do
  # end
end
