defmodule Bench do
  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  def perf do
    1..100_000
    |> Enum.map(&(&1 * 3))
    # |> Enum.filter(Bench.odd?())
    |> Enum.sum
  end

  def odd?(x) do
    if (rem(x, 2) != 0) do
      x
    end
  end


end
