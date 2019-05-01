defmodule FS do
  @moduledoc """
  All Account operations of the exercice

  create/delete client
  simple/multi money transfert
  money conversion
  """

  def create_client(name, main_currency \\ "USD", ammount_deposit \\ 0) do
    true
  end

  def delete_client(name, main_currency \\ "USD", ammount_deposit \\ 0) do
    true
  end

  def transfert(client, to_client, value, currency, direct_conversion \\ true) do
    # if the currency is not available in the to_client %{wallet} and the direct_conversion is_false
    # so create a new wallet with the current currency

    # if the direct_conversion is true, call the conversion function
    true
  end

  def multi_transfert(client, {to_clients}, value, currency, direct_conversion \\ true) do
    # Just split the amount in Enum.count({to_client}) and then,
    # call FS.transfert for each {to_client}

    # If the split roundness is not round, make the rounding down, so the sender will save money.
    true
  end

  def conversion(client, value, from_currency, to_currency) do
    # If the conversion roundness is not round, make the rounding down, so the client will loose
    # money.
    true
  end
end
