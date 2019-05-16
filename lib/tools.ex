defmodule Tools do
  @moduledoc """
  Provides some usefull tools for develloping
  """
  alias Decimal, as: D

  @doc """
  Guard, check is number is a Decimal type.
  """
  defmacro is_decimal(number) do
    quote do
      D.decimal?(unquote(number)) == true
    end
  end

  @doc """
  As it's named, return the type of the element.
  """
  def typeof(self) do
    cond do
      is_float(self) -> "float"
      is_number(self) -> "number"
      is_atom(self) -> "atom"
      is_boolean(self) -> "boolean"
      is_binary(self) -> "binary"
      is_function(self) -> "function"
      is_list(self) -> "list"
      is_tuple(self) -> "tuple"
      is_decimal(self) -> "DecimalNumber"
      true -> "idunno"
    end
  end

  @doc """
  Write on stderr finish by a return line.
  """
  @spec eputs(String.t()) :: atom()
  def eputs(output) do
    IO.puts(:stderr, output)
    :error
  end

  @doc """
  Write on stderr without a return line.
  """
  @spec ewrite(String.t()) :: atom()
  def ewrite(output) do
    IO.write(:stderr, output)
    :error
  end

  @doc """
  Transform integer() or float() amount in Decimal.t()
  """
  @spec type_dec(integer()) :: D.t()
  def type_dec(amount_deposited) when is_integer(amount_deposited), do: D.new(amount_deposited)

  @spec type_dec(float()) :: D.t()
  def type_dec(amount_deposited) when is_float(amount_deposited),
    do: D.from_float(amount_deposited)

  @spec type_dec(D.t()) :: D.t()
  def type_dec(amount_deposited) do
    case D.decimal?(amount_deposited) do
      true -> amount_deposited
      false -> {:error, "Type to decimal invalid."}
    end
  end

  @doc """
  Uniformise the type of valid currency parameter to String.t()
  """
  @spec type_currency(arg) :: String.t() when arg: integer() | any()
  def type_currency(currency) when is_integer(currency), do: Integer.to_string(currency)
  def type_currency(currency), do: currency
end
