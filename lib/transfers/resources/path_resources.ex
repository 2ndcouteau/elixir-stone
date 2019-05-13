defmodule FS.Path_Resources do
  @moduledoc """
  Define the path for the resouce use by the program

  Usage exemple:
  ```
  use FS.Path_Resources

  File.read(@last_conversions, content)
  ```
  """

  defmacro __using__(_) do
    quote do
      @iso_ref "lib/transfers/resources/ISO_4217_reference.json"
      @last_conversions "lib/transfers/resources/last_conversions.json"
    end
  end
end
