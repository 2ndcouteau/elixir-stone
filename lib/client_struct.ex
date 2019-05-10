defmodule ClientStruct do
  defstruct name: "unknown",
            id: 1000,
            # {CODE 986 == NAME "EUR"}
            main_currency: 978,
            wallets: %{978 => 0}
end
