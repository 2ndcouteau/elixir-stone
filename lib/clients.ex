defmodule FS.Clients do
  use Agent, restart: :temporary

  @doc """
  Bucket implementation.
  """
  def start_link(_opt) do
    Agent.start_link(fn -> %ClientStruct{} end)
  end

  @doc """
    Get a `value` from `bucket` by `key`
  """
  def get(pid, key) do
    Agent.get(pid, &Map.get(&1, key))
  end

  @doc """
  Set the `name`,`main_currency`,`amount_deposit` of the client
    name: "unknown",
    id: "000001",
    main_currency: "BRL",
    wallets: %{BRL: 0}
  """
  def put_new_client_infos(client_pid, name, id, main_currency, amount_deposited) do
    Agent.update(client_pid, &Map.put(&1, :name, name))
    Agent.update(client_pid, &Map.put(&1, :id, id))
    Agent.update(client_pid, &Map.put(&1, :main_currency, main_currency))
    Agent.update(client_pid, &Map.put(&1, :wallets, %{main_currency => amount_deposited}))
  end

  def put_new_wallet(client_pid, currency, amount_deposited) do
    old_wallets = FS.Clients.get(client_pid, :wallets)
    new_wallets = Map.put_new(old_wallets, currency, amount_deposited)
    Agent.update(client_pid, &Map.put(&1, :wallets, new_wallets))
  end

  @doc """
  Deletes `key` from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(pid, key) do
    Agent.get_and_update(pid, &Map.pop(&1, key))
  end

  # defp init_wallet(main_currency, amount_deposited) do
  #   {main_currency, amount_deposited}
  # end
end
