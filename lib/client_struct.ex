defmodule ClientStruct do
  defstruct name: "unknown",
            id: 1000,
            # {CODE 986 == NAME "BRL"}
            main_currency: 986,
            wallets: %{986 => 0}
end
