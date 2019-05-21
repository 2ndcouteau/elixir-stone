defmodule FS do
  @moduledoc """
  All Account operations of the exercice

  create/delete client
  simple/multi money transfert
  money conversion
  """

  @doc """
  Create a new client with a `name`

  return the `pid` and the unique `id` of the client
  """
  @spec create_client(String.t(), integer(), integer() | float()) :: {pid(), integer()}
  def create_client(name, main_currency \\ 978, amount_deposited \\ 0) do
    {client_pid, id} = FS.Registry.create_client(Register, name)
    FS.Clients.put_new_client_infos(client_pid, name, id, main_currency, amount_deposited)
    IO.puts("The client account of #{name}:#{inspect(id)} has been created")
    {client_pid, id}
  end

  @doc """
  Delete the client identified by his unique `id`
  """
  @spec delete_client(integer()) :: :ok
  def delete_client(client_id) do
    {_client_pid, id} = FS.Registry.delete_client(Register, client_id)
    IO.puts("The client account #{inspect(id)} has been deleted")
    :ok
  end

  @spec create_wallet(integer(), integer() | String.t(), integer() | float()) ::
          {integer(), integer(), integer() | float()}
  def create_wallet(client_id, currency, amount_deposited \\ 0) do
    client = FS.Registry.fetch(Register, client_id)
    IO.inspect(client)

    {:ok, {client_pid, id, _name}} = Enum.fetch(client, 0)

    FS.Clients.put_new_wallet(client_pid, currency, amount_deposited)
    {id, currency, amount_deposited}
  end

  @spec delete_wallet(integer(), integer()) :: atom()
  def delete_wallet(client_id, currency) do
    client = FS.Registry.fetch(Register, client_id)
    {:ok, {client_pid, _id, _name}} = Enum.fetch(client, 0)

    case FS.Clients.delete_wallet(client_pid, currency) do
      :ok ->
        IO.puts("The client wallet #{inspect(currency)} has been deleted")
        :ok

      :not_empty ->
        IO.puts("The client wallet #{inspect(currency)} is not empty")
        :not_empty

      :not_exist ->
        IO.puts("The client wallet #{inspect(currency)} does not exist")
        :not_exist
    end
  end

  @doc """
  Print the struct client.s infos

  By the string name, you can fetch several account with same name.
  Only ID are uniques.
  """
  @spec print_client_infos(binary() | pos_integer() | String.t()) :: :ok | :error
  def print_client_infos(client) when is_integer(client) do
    client = FS.Clients.get_client_back_infos(client)

    case client != [] and client != nil do
      true ->
        IO.puts("---------------------")
        {client_pid, id, name} = client
        IO.puts("ID: #{id}, Name: #{name}")

        main_currency = FS.Clients.get(client_pid, :main_currency)
        {numeric_code, alpha_code, minor_unit} = FS.Transfer.get_one_code(Transfer, main_currency)
        IO.puts("Main Currency: #{alpha_code}, #{numeric_code}, minor_unit = #{minor_unit}")

        wallets = FS.Clients.get(client_pid, :wallets)

        Enum.each(wallets, fn {code, value} ->
          {_numeric_code, alpha_code, _minor_unit} = FS.Transfer.get_one_code(Transfer, code)
          value = Decimal.to_string(value)
          IO.puts("#{alpha_code}: #{value}")
        end)

        IO.puts("---------------------")

      false ->
        Tools.eputs("This ID does not exist.")
    end
  end

  @doc """
  Print the IDs and Names of clients with the given name.

  By the string name, you can fetch several account with same name.
  Only ID are uniques.
  """
  def print_client_infos(client) when is_binary(client) do
    clients = FS.Registry.fetch(Register, client)

    case clients != [] do
      true ->
        Enum.each(clients, fn {_pid, id, name} -> IO.puts("ID: #{id}, Name: #{name}") end)
        IO.puts("Please relaunch the function with the corresponding `ID`.")

      false ->
        Tools.eputs("This name does not exist.")
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
  defdelegate transfer(from_client_id, to_client_id, from_currency, value, direct_conversion),
    to: FS.Transfer,
    as: :transfer

  @doc """
  Transfer value from one account to another.

  transfer/3

  An account is a partcular wallet of a particular client.
  The id account is contruct by the addition of the id_client and the id_currency of the wallet

  Exemple:
  For the account_id = 45978, the id_client is 45000 and the wallet is 978 => EUR
  """
  defdelegate transfer(account_id, to_account_id, value), to: FS.Transfer, as: :transfer

  @doc """
  Transfer value from wallet to another wallet for the same Client

  transfer/4

  - wallet/to_wallet :: currency_code :: integer in list_currency ISO_4217
  """
  defdelegate transfer(from_client_id, from_wallet, to_wallet, value),
    to: FS.Transfer,
    as: :transfer

  @doc """
  multi_transfer/5

  Transfer a `value` from a `client` `wallet` to one or several clients wallets.
  Direct conversion can be made.
  The value is split in N wallet destinations.
  """
  defdelegate multi_transfer(
                from_client_id,
                to_clients_ids,
                from_currency,
                value,
                direct_conversion
              ),
              to: FS.Transfer,
              as: :transfer

  @doc """
  Transfer value from one account to a list of account.

  multi_transfer/3

  An account is a partcular wallet of a particular client.
  The id account is contruct by the addition of the id_client and the id_currency of the wallet

  Exemple:
  For the account_id = 45978, the id_client is 45000 and the wallet is 978 => EUR
  """
  defdelegate multi_transfer(account_id, to_account_id, value), to: FS.Transfer, as: :transfer

  @doc """
  ## Conversion

  Make conversion between two currencies.
  Base : EUR

  This conversion takes into account the numbers the `minor number` of each currencies.
  The default context has a precision of 28, the rounding algorithm is :half_up.
  The set trap enablers are :invalid_operation and :division_by_zero
  """
  defdelegate conversion(value, from_currency, to_currency), to: Currency_API, as: :conversion
end
