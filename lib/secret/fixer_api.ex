defmodule FS.Fixer_API do
  @moduledoc """
  Define the attribute @key_api to retrive it in other place.

  Usage exemple:
  ```
  use FS.Fixer_API

  IO.puts("The api key is \#{@key_api}")
  ```
  """

  # julag@simpleemail.info == "8be9b6f827c2c8f88571572481b20002"
  # tupomiri@quick-mail.club == "2c5f01fdc85d23fcad6c1a716eba0d0e"
  defmacro __using__(_) do
    quote do
      ## OLD KEYS
      # @key_api "8be9b6f827c2c8f88571572481b20002"
      ## FRESH ONES
      @key_api "2c5f01fdc85d23fcad6c1a716eba0d0e"
    end
  end
end
