defmodule ClientStruct do
  defstruct name: "unknown",
            id: "0001000",
            # Should be {CODE 986, NAME "BRL"}
            main_currency: "BRL",
            wallets: %{986 => 0}
end
