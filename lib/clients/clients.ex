defmodule FS.Clients do
  use Agent, restart: :temporary

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
  @spec put_new_client_infos(pid(), String.t(), integer(), integer(), integer()) :: :ok
  def put_new_client_infos(client_pid, name, id, main_currency, amount_deposited) do
    Agent.update(client_pid, &Map.put(&1, :name, name))
    Agent.update(client_pid, &Map.put(&1, :id, id))
    Agent.update(client_pid, &Map.put(&1, :main_currency, main_currency))
    Agent.update(client_pid, &Map.put(&1, :wallets, %{main_currency => amount_deposited}))
    :ok
  end

  @doc """
  Create a new wallet in the wallets of the client.

  If the wallet already exist, the wallets are not updated
  """
  @spec put_new_wallet(pid(), integer(), integer()) :: atom()
  def put_new_wallet(client_pid, currency, amount_deposited) do
    old_wallets = FS.Clients.get(client_pid, :wallets)
    new_wallets = Map.put_new(old_wallets, currency, amount_deposited)

    if old_wallets != new_wallets do
      Agent.update(client_pid, &Map.put(&1, :wallets, new_wallets))
      :ok
    else
      :already_exists
    end
  end

  @doc """
  Delete a wallet from the client wallets.

  The wallet has to exist and to be empty ==> 0, else an :error is return
  Return error:
    - :not_exist
    - :not_empty
  """
  @spec delete_wallet(pid(), integer()) :: atom()
  def delete_wallet(client_pid, currency) do
    old_wallets = FS.Clients.get(client_pid, :wallets)

    case Map.get(old_wallets, currency) do
      0 ->
        new_wallets = Map.delete(old_wallets, currency)
        Agent.update(client_pid, &Map.put(&1, :wallets, new_wallets))
        :ok

      nil ->
        :not_exist

      _ ->
        :not_empty
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
