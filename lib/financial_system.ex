defmodule FinancialSystem do
  @moduledoc """
  Documentation for FinancialSystem.
  """
  use Application

  def start(_type, _args) do
    FS.Supervisor.start_link(name: FS.Supervisor)
  end
end
