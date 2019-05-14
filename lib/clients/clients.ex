defmodule FS.Clients do
  use Agent, restart: :temporary
  use DecimalArithmetic

  alias Decimal, as: D

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
    code_currency = type_currency(main_currency)

    case FS.Transfer.get_one_code(Transfer, code_currency) do
      {numeric_code, _alpha_code, minor_unit} ->
        Agent.update(client_pid, &Map.put(&1, :main_currency, String.to_integer(numeric_code)))

        dec_amount =
          type_dec(amount_deposited)
          |> D.round(String.to_integer(minor_unit))

        Agent.update(
          client_pid,
          &Map.put(&1, :wallets, %{String.to_integer(numeric_code) => dec_amount})
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
    code_currency = type_currency(currency)

    case FS.Transfer.get_one_code(Transfer, code_currency) do
      {numeric_code, _alpha_code, minor_unit} ->
        dec_amount =
          type_dec(amount_deposited)
          |> D.round(String.to_integer(minor_unit))

        new_wallets = Map.put_new(old_wallets, String.to_integer(numeric_code), dec_amount)

        if old_wallets != new_wallets do
          Agent.update(client_pid, &Map.put(&1, :wallets, new_wallets))
          :ok
        else
          # IO.warn("Please use transfer function.")
          :already_exists
        end

      {:error, reason} ->
        IO.warn(reason)
        {:error, reason}
    end
  end

  @spec type_currency(integer() | String.t()) :: String.t()
  defp type_currency(currency) do
    if is_binary(currency) do
      currency
    else
      Integer.to_string(currency)
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
    value = Map.get(old_wallets, currency)

    if D.decimal?(value) && D.equal?(value, ~m(0)) do
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
  Transform integer() or float() amount in Decimal.t()
  """
  @spec type_dec(integer() | float()) :: D.t()
  def type_dec(amount_deposited) do
    if D.decimal?(amount_deposited) do
      IO.puts("HELLOOOO I AM DECIMAL !!! ")
      amount_deposited
    else
      dec_amount =
        with true <- is_integer(amount_deposited) do
          D.new(amount_deposited)
        else
          false ->
            D.from_float(amount_deposited)
        end

      dec_amount
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
