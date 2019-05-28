defmodule ToolsTest do
  use ExUnit.Case

  test "Check Type currency " do
    # Check regular Integer
    assert Tools.type_currency(978) == "978"
    assert Tools.type_currency(012) == "012"
    assert Tools.type_currency(008) == "008"

    # Check Regular string
    assert Tools.type_currency("008") == "008"
  end
end
