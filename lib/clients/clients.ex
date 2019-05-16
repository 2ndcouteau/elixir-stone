defmodule FS.Clients do
  use Agent, restart: :temporary

  defguardp is_client(id) when is_integer(id) and rem(id, 1000) == 0 and id >= 1000

  # use DecimalArithmetic

  alias Decimal, as: D

  @type currency :: integer() | String.t()

  @doc """
  Bucket FS.Clients implementation.
  """
  def start_link(_opt) do
    Agent.start_link(fn -> %ClientStruct{} end)
  end

  @doc """
  Set the `name`, `id`, `main_currency`, and the first wallet of the client.
    name: "unknown",
    id: "1000",
    main_currency: "978",
    wallets: %{978: 0}
  """
  @spec put_new_client_infos(
          pid(),
          String.t(),
          integer(),
          integer() | String.t(),
          integer() | float()
        ) :: :ok | {:error, String.t()}
  def put_new_client_infos(client_pid, name, id, main_currency, amount_deposited) do
    Agent.update(client_pid, &Map.put(&1, :name, name))
    Agent.update(client_pid, &Map.put(&1, :id, id))
    code_currency = Tools.type_currency(main_currency)

    case FS.Transfer.get_one_code(Transfer, code_currency) do
      {numeric_code, _alpha_code, minor_unit} ->
        Agent.update(client_pid, &Map.put(&1, :main_currency, numeric_code))

        dec_amount =
          Tools.type_dec(amount_deposited)
          |> D.round(String.to_integer(minor_unit))

        Agent.update(
          client_pid,
          &Map.put(&1, :wallets, %{numeric_code => dec_amount})
        )

        :ok

      {:error, reason} ->
        # IO.warn(reason)
        {:error, reason}
    end

    :ok
  end

  @doc """
  Create a new wallet in the wallets of the client.

  If the wallet already exist, the wallets are not updated
  """
  @spec put_new_wallet(pid(), integer() | String.t(), integer() | float()) :: atom()
  def put_new_wallet(client_pid, currency, amount_deposited) do
    old_wallets = FS.Clients.get(client_pid, :wallets)
    code_currency = Tools.type_currency(currency)

    case FS.Transfer.get_one_code(Transfer, code_currency) do
      {numeric_code, _alpha_code, minor_unit} ->
        dec_amount =
          Tools.type_dec(amount_deposited)
          |> D.round(String.to_integer(minor_unit))

        new_wallets = Map.put_new(old_wallets, numeric_code, dec_amount)

        if old_wallets != new_wallets do
          Agent.update(client_pid, &Map.put(&1, :wallets, new_wallets))
          :ok
        else
          Tools.eputs("Wallet already exists. Please use transfer functions.")
          :already_exists
        end

      {:error, reason} ->
        IO.warn(reason)
        {:error, reason}
    end
  end

  # def get_wallets_infos(client_pid)

  @doc """
  Delete a wallet from the client wallets.

  The wallet has to exist and to be empty ==> 0, else an :error is return
  Return error:
    - :not_exist
    - :not_empty
  """
  @spec delete_wallet(pid(), currency()) :: atom()
  def delete_wallet(client_pid, currency) do
    currency = Tools.type_currency(currency)
    old_wallets = FS.Clients.get(client_pid, :wallets)
    value = Map.get(old_wallets, currency)

    if value != nil and D.equal?(value, D.new(0)) do
      new_wallets = Map.delete(old_wallets, currency)
      Agent.update(client_pid, &Map.put(&1, :wallets, new_wallets))
      :ok
    else
      case value do
        nil ->
          :not_exist

        _ ->
          :not_empty
      end
    end
  end

  @doc """
  Get the client info from Register
  """
  @spec get_client_back_infos(integer()) :: {pid(), integer(), String.t()} | nil
  def get_client_back_infos(client) when is_client(client) do
    FS.Registry.fetch(Register, client)
    |> Enum.at(0)
  end

  @doc """
  Get informations about one particular wallet of a particular client.
  """
  @spec get_one_wallet_infos(integer(), String.t()) :: {String.t(), D.t()} | atom()
  def get_one_wallet_infos(client_id, currency) do
    client = FS.Clients.get_client_back_infos(client_id)

    case valid_client_back_infos(client) do
      {client_pid, _id, _name} ->
        wallets = FS.Clients.get(client_pid, :wallets)

        Enum.find(wallets, fn {code, _value} ->
          # IO.puts("WINFO code" <> Tools.typeof(code))
          # IO.puts("WINFO currency" <> Tools.typeof(currency))
          code == currency
        end)

      false ->
        Tools.eputs("This ID does not exist.")
    end
  end

  @doc """
  Check with is the client exist and return each element
  """
  @spec valid_client_back_infos({pid(), integer(), String.t()} | nil) ::
          {pid(), integer(), String.t()} | false
  def valid_client_back_infos(client_infos) do
    case client_infos != nil do
      true ->
        {client_pid, id, name} = client_infos
        {client_pid, id, name}

      false ->
        false
    end
  end

  @doc """
    Get a `value` from `bucket_pid` by `key`
  """
  @spec get(pid(), atom()) :: any()
  def get(pid, key) do
    Agent.get(pid, &Map.get(&1, key))
  end

  @doc """
  Deletes `key` from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  @spec delete(pid(), atom()) :: term()
  def delete(pid, key) do
    Agent.get_and_update(pid, &Map.pop(&1, key))
  end
end
