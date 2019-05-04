defmodule FS do
  @moduledoc """
  All Account operations of the exercice

  create/delete client
  simple/multi money transfert
  money conversion
  """

  # def create_client(name, main_currency \\ "USD", amount_deposited \\ 0) do
  def cc(name, main_currency \\ "USD", amount_deposited \\ 0) do
    # FS.Registry.hello_test()
    {client_pid, id} = FS.Registry.create_client(Register, name)
    # {client_pid, id} = FS.Registry.fetch(Register, name)
    FS.Clients.put(client_pid, name, id, main_currency, amount_deposited)
  end

  #
  # def delete_client(client_id) do
  #   true
  # end
  #
  # def create_wallet(client_id, currency, value \\ 0) do
  #   true
  # end
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
