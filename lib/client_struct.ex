defmodule ClientStruct do
  defstruct name: "unknown",
            id: "000001",
            main_currency: "BRL",
            wallet: %{BRL: 0}
end
