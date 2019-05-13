defmodule FinancialSystem.MixProject do
  use Mix.Project

  # Use a different elixir version ~>1.8 instead of ~>1.5
  def project do
    [
      app: :financial_system,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FinancialSystem, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:decimal, "~> 1.7.0"},
      # {:decimal_arithmetic, "~> 0.1.2"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:poison, "~> 4.0.1"},
      {:httpoison, "~> 1.5.1"}
      # {:named_args, "~> 0.1.0"}
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end
end
