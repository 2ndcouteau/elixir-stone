defmodule FS.Registry do
  @moduledoc """
  Associate the bucket name to the bucket process.
  """

  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def fetch(server, name) do
    GenServer.call(server, {:fetch, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create_client(server, name) do
    GenServer.call(server, {:create_client, name})
  end

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  ## Server Callbacks

  def init(:ok) do
    names = %{}
    refs = %{}
    ids = %{"bank" => 0}
    {:ok, {names, refs, ids}}
  end

  @doc """
  Fetch the pid of the `name` process in the `registry` state.
  """
  def handle_call({:fetch, name}, _from, {names, refs, ids}) do
    {_, id} = Map.fetch(ids, name)
    {_, client_pid} = Map.fetch(names, name)
    {:reply, {client_pid, id}, {names, refs, ids}}
  end

  def handle_call({:create_client, name}, _from, {names, refs, ids}) do
    ### ? Use only name or id to check ?
    # if Map.has_key?(names, name) do
    #   {:reply, name, {names, refs, ids}}
    # else
    {:ok, client_pid} = DynamicSupervisor.start_child(FS.ClientsSupervisor, FS.Clients)
    ref = Process.monitor(client_pid)
    refs = Map.put(refs, ref, name)

    # !! Naive way !!
    # Must be UNIQUE
    # Should check for a duplicated entry
    id =
      Map.values(ids)
      |> Enum.max()
      |> (fn x -> x + 1 end).()

    ids = Map.put(ids, name, id)
    names = Map.put(names, name, client_pid)
    {:reply, {client_pid, id}, {names, refs, ids}}
    # end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    ## ?? Delete the good name --> check the ID ...
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

## OLD
#   ## Server Callbacks
#
#   def init(:ok) do
#     {:ok, %{"toto" => "tutu"}}
#   end
#
#   def handle_call({:lookup, name}, _from, names) do
#     {:reply, Map.fetch(names, name), names}
#   end
#
#   def handle_call({:create, name}, _from, names) do
#     if Map.has_key?(names, name) do
#       {:reply, names, names}
#     else
#       IO.puts("EZLIFE")
#       {:ok, bucket} = FS.Bucket.start_link([])
#       {:reply, Map.put(names, name, bucket), names}
#     end
#   end
# end
