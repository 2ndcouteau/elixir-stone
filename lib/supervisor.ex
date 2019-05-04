defmodule FS.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: FS.ClientsSupervisor, strategy: :one_for_one},
      {FS.Registry, name: Register}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
