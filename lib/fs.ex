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
  def create_client(name, main_currency \\ 986, amount_deposited \\ 0) do
    {client_pid, id} = FS.Registry.create_client(Register, name)
    FS.Clients.put_new_client_infos(client_pid, name, id, main_currency, amount_deposited)
    IO.puts("The client account of #{name}:#{inspect(id)} has been created")
    {client_pid, id}
  end

  @doc """
  Delete the client identified by his unique `id`
  """
  def delete_client(client_id) do
    {_client_pid, id} = FS.Registry.delete_client(Register, client_id)
    IO.puts("The client account #{inspect(id)} has been deleted")
  end

  def create_wallet(client_id, currency, amount_deposited \\ 0) do
    client = FS.Registry.fetch(Register, client_id)
    {:ok, {client_pid, id, _name}} = Enum.fetch(client, 0)
    FS.Clients.put_new_wallet(client_pid, currency, amount_deposited)
    {id, currency, amount_deposited}
  end

  #
  # def transfert(client_id, to_client_id, value, currency, direct_conversion \\ true) do
  #   # if the currency is not available in the to_client %{wallet} and the direct_conversion is_false
  #   # so create a new wallet with the current currency
  #
  #   # if the direct_conversion is true, call the conversion function
  #   true
  # end
  #
  # def multi_transfert(client_id, {to_clients_id}, value, currency, direct_conversion \\ true) do
  #   # Just split the amount in Enum.count({to_client}) and then,
  #   # call FS.transfert for each {to_client}
  #
  #   # If the split roundness is not round, make the rounding down, so the sender will save money.
  #   true
  # end
  #
  # def conversion(client_id, value, from_currency, to_currency) do
  #   # If the conversion roundness is not round, make the rounding down, so the client will loose
  #   # money.
  #   true
  # end
end
