defmodule ClientStruct do
  use DecimalArithmetic

  defstruct name: "unknown",
            id: 1000,
            # {CODE 978 == NAME "EUR"}
            main_currency: "978",
            wallets: %{"978" => ~m(0)}
end
