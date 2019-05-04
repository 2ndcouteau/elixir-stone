defmodule ClientStruct do
  defstruct name: "unknown",
            id: "000001",
            main_currency: "BRL",
            wallets: %{BRL: 0}
end
