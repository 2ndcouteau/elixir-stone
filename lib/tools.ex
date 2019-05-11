defmodule Tools do
  @moduledoc """
  Provides some usefull tools for develloping
  """

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
      true -> "idunno"
    end
  end
end
