defmodule KVServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    port =
      String.to_integer(System.get_env("PORT") || raise("missing $PORT environnement variable"))

    # PROCESSES UNDER SUPERVISING DEFITIONS
    # List all child processes to be supervised
    children = [
      {Task.Supervisor, name: KVServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> KVServer.accept(port) end}, restart: :permanent)
      # Starts a worker by calling: KVServer.Worker.start_link(arg)
      # {KVServer.Worker, arg}
    ]

    # OPTIONS DEFINITIONS
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KVServer.Supervisor]

    # The real Start Command !
    Supervisor.start_link(children, opts)
  end
end
