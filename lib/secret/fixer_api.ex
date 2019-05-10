defmodule FS.Fixer_API do
  @moduledoc """
  Define the attribute @key_api to retrive it in other place.

  Usage exemple:
  ```
  use FS.Fixer_API

  IO.puts("The api key is \#{@key_api}")
  ```
  """

  # julag@simpleemail.info
  defmacro __using__(_) do
    quote do
      @key_api "8be9b6f827c2c8f88571572481b20002"
    end
  end
end
