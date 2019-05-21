defmodule FS.Transfer do
  @moduledoc """
  Transfert client/server

  """

  use GenServer

  alias Decimal, as: D

  ## Private guards

  defguardp is_account(id) when is_integer(id) and id >= 1000 and rem(id, 1000) != 0
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
  Procede to the transfer operation.
  Remove value from the `client` wallet. Add value to the `to_cient` wallet.
  The destination wallet is depends of the parameter `direct_conversion`.
  If this last is `:true`, the value is convert to the `main_currency` of the `to_client`.
  Else, the value is put on the same currency wallet.
  """
  @spec make_transfer(
          {pid(), pos_integer(), String.t()},
          {String.t(), String.t(), String.t()},
          D.t(),
          [{pid(), pos_integer(), String.t(), D.t()}]
        ) ::
          [any()]
  # {String.t(), D.t(), D.t()}
  def make_transfer(from_client, from_currency, value, chk_values) do
    # Get Client infos
    {from_client_pid, from_client_id, _from_client_name} = from_client
    {numeric_code, _alpha_code, _minor_unit} = from_currency
    debit_value = D.mult(value, -1)
    FS.Clients.update_wallet(from_client_pid, from_client_id, numeric_code, debit_value)

    # Debit Client
    # {_currency, _new_wallet_value, diff_amount} =

    for {to_client_pid, to_client_id, to_currency, conv_value} <- chk_values do
      case FS.Clients.get_one_wallet_infos(to_client_id, to_currency) do
        nil ->
          _ = FS.Clients.put_new_wallet(to_client_pid, to_currency, conv_value)
          :ok

        # {to_currency, credit_value, credit_value}

        _ ->
          FS.Clients.update_wallet(to_client_pid, to_client_id, to_currency, conv_value)
          :ok
      end
    end
  end

  @doc """
  Transfer value from one given currency wallet to another client.

  transfer/5

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
          number(),
          boolean()
        ) :: {String.t(), D.t(), D.t()} | atom()
  def transfer(from_client_id, to_client_id, from_currency, value, direct_conversion)
      when is_client(from_client_id)
      when is_client(to_client_id)
      when is_wallet(from_currency)
      when is_number(value)
      when value > 0
      when is_boolean(direct_conversion) do
    value = Tools.type_dec(value)

    from_currency_code =
      Tools.type_currency(from_currency)
      |> (&get_one_code(Transfer, &1)).()

    from_client = FS.Clients.get_client_back_infos(from_client_id)
    to_client = FS.Clients.get_client_back_infos(to_client_id)

    chk_clients = check_clients(from_client, from_client_id, [to_client], [to_client_id])

    case chk_clients do
      {:error, reason} ->
        Tools.eputs(reason)

      :ok ->
        chk_currencies =
          check_currencies(from_currency, from_currency_code, [to_client], direct_conversion)

        case chk_currencies do
          {:error, reason} ->
            Tools.eputs(reason)

          _ ->
            chk_values = check_values(chk_currencies, from_client_id, from_currency_code, value)

            case chk_values do
              {:error, reason} ->
                Tools.eputs(reason)

              _ ->
                make_transfer(from_client, from_currency_code, value, chk_values)
            end
        end
    end
  end

  @doc """
  Transfer value from one account to another.

  transfer/3

  An account is a partcular wallet of a particular client.
  The id account is contruct by the addition of the id_client and the id_currency of the wallet

  Exemple:
  For the account_id = 45978, the id_client is 45000 and the wallet is 978 => EUR
  """
  @spec transfer(integer(), integer(), number()) :: atom()
  def transfer(account_id, to_account_id, value)
      when is_account(account_id)
      when is_account(to_account_id)
      when is_number(value)
      when value > 0 do
    value = Tools.type_dec(value)

    {from_client, from_client_id, from_currency_id} = extract_info_account_id(account_id)
    {to_client, to_client_id, to_currency_id} = extract_info_account_id(to_account_id)

    from_currency_code =
      Tools.type_currency(from_currency_id)
      |> (&get_one_code(Transfer, &1)).()

    chk_clients = check_clients(from_client, from_client_id, [to_client], [to_client_id])

    case chk_clients do
      {:error, reason} ->
        Tools.eputs(reason)

      _ ->
        chk_currencies =
          check_currencies_account(from_currency_code, from_currency_id, [to_client], [
            to_currency_id
          ])

        case chk_currencies do
          {:error, reason} ->
            Tools.eputs(reason)

          _ ->
            chk_values = check_values(chk_currencies, from_client_id, from_currency_code, value)

            case chk_values do
              {:error, reason} ->
                Tools.eputs(reason)

              _ ->
                make_transfer(from_client, from_currency_code, value, chk_values)
            end
        end
    end
  end

  @doc """
  Transfer value from wallet to another wallet for the same Client

  transfer/4

  - wallet/to_wallet :: currency_code :: integer in list_currency ISO_4217
  """
  @spec transfer(integer(), integer(), integer(), number()) :: atom()
  def transfer(from_client_id, from_wallet, to_wallet, value)
      when is_client(from_client_id)
      when is_wallet(from_wallet)
      when is_wallet(to_wallet)
      when is_number(value)
      when value > 0 do
    value = Tools.type_dec(value)
    from_wallet = Tools.type_currency(from_wallet)
    to_wallet = Tools.type_currency(to_wallet)
    from_client = FS.Clients.get_client_back_infos(from_client_id)

    from_wallet_code =
      Tools.type_currency(from_wallet)
      |> (&get_one_code(Transfer, &1)).()

    chk_clients = check_clients(from_client, from_client_id, [from_client], [from_client_id])

    case chk_clients do
      {:error, reason} ->
        Tools.eputs(reason)

      _ ->
        chk_currencies =
          check_currencies_account(from_wallet_code, from_wallet, [from_client], [to_wallet])

        case chk_currencies do
          {:error, reason} ->
            Tools.eputs(reason)

          _ ->
            chk_values = check_values(chk_currencies, from_client_id, from_wallet_code, value)

            case chk_values do
              {:error, reason} ->
                Tools.eputs(reason)

              _ ->
                make_transfer(from_client, from_wallet_code, value, chk_values)
            end
        end
    end
  end

  @doc """
  Decompose the `account_id` in `client_id` and `currency_code`.

  Exemple:
  ```
  account_id == 8840
  client_id == 8000
  currency == 840 == "USD"
  ```
  Return -> {{client_pid, client_id, client_name}, client_id, currency_code}
  """
  @spec extract_info_account_id(integer()) ::
          {{pid(), integer(), String.t()}, integer(), String.t()}
          | {nil, integer(), String.t()}
  def(extract_info_account_id(account_id)) do
    currency =
      rem(account_id, 1000)
      |> Integer.to_string()

    client_id =
      div(account_id, 1000)
      |> Kernel.*(1000)

    client = FS.Clients.get_client_back_infos(client_id)

    {client, client_id, currency}
  end

  @doc """
  Decompose the `account_ids` in `clients_ids` and `currencies`.

  Returna tuple of 3 list.
  """
  @spec extract_info_list_account_id([integer()]) ::
          {[{pid(), integer(), String.t()} | nil], [integer()], [String.t()]}
  def(extract_info_list_account_id(accounts_ids)) do
    currencies =
      Enum.map(accounts_ids, fn account_id ->
        rem(account_id, 1000)
        |> Integer.to_string()
      end)

    clients_ids =
      Enum.map(accounts_ids, fn account_id ->
        div(account_id, 1000)
        |> Kernel.*(1000)
      end)

    clients =
      Enum.map(clients_ids, fn client_id ->
        FS.Clients.get_client_back_infos(client_id)
      end)

    {clients, clients_ids, currencies}
  end

  @doc """
  multi_transfer/5

  Transfer a `value` from a `client` `wallet` to one or several clients wallets.
  Direct conversion can be made.
  The value is split in N wallet destinations.
  """
  @spec transfer(
          integer(),
          [integer()],
          integer() | String.t(),
          number(),
          boolean()
        ) :: {String.t(), D.t(), D.t()} | atom()
  def multi_transfer(from_client_id, to_clients_ids, from_currency, value, direct_conversion)
      when is_client(from_client_id)
      when is_list(to_clients_ids)
      when is_wallet(from_currency)
      when is_number(value)
      when value > 0
      when is_boolean(direct_conversion) do
    value = Tools.type_dec(value)
    from_currency = Tools.type_currency(from_currency)

    from_currency_code =
      Tools.type_currency(from_currency)
      |> (&get_one_code(Transfer, &1)).()

    from_client = FS.Clients.get_client_back_infos(from_client_id)

    to_clients = FS.Clients.get_clients_list_back_infos(to_clients_ids)

    chk_clients = check_clients(from_client, from_client_id, to_clients, to_clients_ids)

    case chk_clients do
      {:error, reason} ->
        Tools.eputs(reason)

      :ok ->
        chk_currencies =
          check_currencies(from_currency, from_currency_code, to_clients, direct_conversion)

        case chk_currencies do
          {:error, reason} ->
            Tools.eputs(reason)

          _ ->
            chk_values = check_values(chk_currencies, from_client_id, from_currency_code, value)

            case chk_values do
              {:error, reason} ->
                Tools.eputs(reason)

              _ ->
                make_transfer(from_client, from_currency_code, value, chk_values)
            end
        end
    end
  end

  @doc """
  Transfer value from one account to a list of account.

  multi_transfer/3

  An account is a partcular wallet of a particular client.
  The id account is contruct by the addition of the id_client and the id_currency of the wallet

  Exemple:
  For the account_id = 45978, the id_client is 45000 and the wallet is 978 => EUR
  """
  @spec multi_transfer(integer(), [integer()], number()) :: atom()
  def multi_transfer(account_id, to_account_id, value)
      when is_account(account_id)
      when is_list(to_account_id)
      when is_number(value)
      when value > 0 do
    value = Tools.type_dec(value)

    {from_client, from_client_id, from_currency_id} = extract_info_account_id(account_id)
    {to_client, to_client_id, to_currency_id} = extract_info_list_account_id(to_account_id)

    from_currency_code =
      Tools.type_currency(from_currency_id)
      |> (&get_one_code(Transfer, &1)).()

    chk_clients = check_clients(from_client, from_client_id, to_client, to_client_id)

    case chk_clients do
      {:error, reason} ->
        Tools.eputs(reason)

      _ ->
        chk_currencies =
          check_currencies_account(
            from_currency_code,
            from_currency_id,
            to_client,
            to_currency_id
          )

        case chk_currencies do
          {:error, reason} ->
            Tools.eputs(reason)

          _ ->
            chk_values = check_values(chk_currencies, from_client_id, from_currency_code, value)

            case chk_values do
              {:error, reason} ->
                Tools.eputs(reason)

              _ ->
                make_transfer(from_client, from_currency_code, value, chk_values)
            end
        end
    end
  end

  @doc """
  Check if each member of the client list exists.
  """
  @spec check_clients(tuple(), integer(), [tuple()], [integer()]) :: atom() | {:error, String.t()}
  def check_clients(client, client_id, to_clients, to_clients_ids) do
    to_client_invalid =
      Enum.find(
        Enum.zip(to_clients, to_clients_ids),
        fn {to_clients, _to_clients_ids} ->
          to_clients == nil
        end
      )

    cond do
      client == nil ->
        {:error, "Client #{client_id} does not exist."}

      to_client_invalid != nil ->
        {nil, to_client_id} = to_client_invalid
        {:error, "Client #{to_client_id} does not exist."}

      true ->
        :ok
    end
  end

  @doc """
  Check if this client exists.
  """
  @spec check_one_client(tuple(), integer()) :: atom() | {:error, String.t()}
  def check_one_client(client, client_id) do
    if client == nil do
      {:error, "Client #{client_id} does not exist."}
    else
      :ok
    end
  end

  @doc """
  Check is each `from currency` and `to_currencies` are valid and return a list of the
  `to_currencies`

  `to_currencies` can be get from `main_currency` of each client if direct_conversion is `:true` or
  can be generated with the `from_currency` with the number of clients.
  """
  @spec check_currencies(
          integer() | String.t(),
          {String.t(), String.t(), String.t()},
          [{pid(), integer(), String.t()}] | [nil],
          boolean()
        ) ::
          [{pid(), pos_integer(), String.t()}] | {:error, String.t()}
  def check_currencies(from_currency, from_currency_code, to_clients, direct_conversion) do
    case from_currency_code do
      {:error, _} ->
        {:error, "Currency #{from_currency} does not exist."}

      {numeric_code, _alpha_code, _minor_code} ->
        case direct_conversion do
          true ->
            get_all_currencies(to_clients)

          false ->
            Enum.map(to_clients, fn
              {to_client_pid, to_client_id, _to_client_name} ->
                {to_client_pid, to_client_id, numeric_code}
            end)
        end
    end
  end

  @doc """
  Check all currencies passed in parameter.

  The first unvalid currency encountred returns a error message.
  Return the list of each client with his destination currency.
  """
  @spec check_currencies_account({String.t(), String.t(), String.t()}, String.t(), [tuple], [
          String.t()
        ]) ::
          [{pid(), pos_integer(), String.t()}] | {:error, String.t()}
  def check_currencies_account(from_currency, from_currency_id, to_clients, to_currencies) do
    case from_currency do
      {:error, _reason} ->
        {:error, "Currency #{from_currency_id} does not exist."}

      _ ->
        clients_currencies =
          Enum.zip(to_clients, to_currencies)
          |> Enum.map(fn {{to_client_pid, to_client_id, _name}, currency} ->
            {to_client_pid, to_client_id, currency}
          end)

        check_status =
          Enum.find(
            clients_currencies,
            fn {_to_client_pid, _to_client_id, currency} ->
              get_one_code(Transfer, currency) == {:error, "Currency unavailable"}
            end
          )

        if check_status == nil do
          clients_currencies
        else
          {_to_client, _to_client_id, to_currency} = check_status
          {:error, "Currency #{to_currency} does not exist."}
        end
    end
  end

  @doc """
  Get the main_currency of each client pass in the `to_clients` list.
  """
  @spec get_all_currencies(pid()) :: [{pid(), integer(), String.t()}]
  def get_all_currencies(to_clients) do
    Enum.map(to_clients, fn
      {to_client_pid, to_client_id, _to_client_name} ->
        {to_client_pid, to_client_id, FS.Clients.get(to_client_pid, :main_currency)}
    end)
  end

  @doc """
  Check all conversions values.

  If one conversion value is zero, so that mean that the change rate is to high to convert this value
  """
  @spec check_values(
          [{pid(), pos_integer(), String.t()}],
          pos_integer(),
          {String.t(), String.t(), String.t()},
          D.t()
        ) ::
          [{pid(), integer, String.t(), D.t()}] | {:error, String.t()}
  def check_values(clients_currencies, from_client_id, from_currency_code, value) do
    split_value = Decimal.div(value, Enum.count(clients_currencies))
    {from_numeric_code, _alpha_code, _minor_unit} = from_currency_code

    case FS.Clients.get_one_wallet_infos(from_client_id, from_numeric_code) do
      nil ->
        {:error, "The client #{from_client_id} does not have a wallet #{from_numeric_code}."}

      {_w_currency, w_value} ->
        case Decimal.cmp(value, w_value) do
          :gt ->
            {:error, "The client #{from_client_id} does not have enough money.
Founds available: #{w_value}"}

          _ ->
            cond do
              Decimal.cmp(split_value, 0) != :gt ->
                {:error, "Value: #{value} is not enough to be split."}

              true ->
                all_conversions =
                  Enum.map(clients_currencies, fn {client_pid, client_id, to_currency} ->
                    {client_pid, client_id, to_currency,
                     Currency_API.conversion(split_value, from_numeric_code, to_currency)}
                  end)

                check_status =
                  Enum.find(
                    all_conversions,
                    fn {_to_client_pid, _to_client_id, _currency, conv_value} ->
                      Decimal.cmp(conv_value, 0) != :gt
                    end
                  )

                if check_status == nil do
                  all_conversions
                else
                  {_to_client_pid, _to_client, to_currency, _conv_value} = check_status

                  {:error,
                   "Value: #{split_value} is not enough to be convert in #{to_currency} currency."}
                end
            end
        end
    end
  end

  ## Server Callbacks

  @doc """
  Init the state of the Server

  iso_ref,
  last_conversions,
  available_currencies,
  {:ok, {iso_ref, last_conversions, available_currencies}}


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
end
