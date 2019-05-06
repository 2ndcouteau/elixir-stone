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
    ids = %{}
    refs = %{}
    id_name = [{0, "bank"}]
    {:ok, {ids, refs, id_name}}
  end

  @doc """
  Fetch the pid of the `name` process in the `registry` state.
  """
  def handle_call({:fetch, name_or_id}, _from, {ids, refs, id_name}) do
    {id, name} = FS.Registry.Gin.get_id_name(name_or_id, id_name)
    {_, client_pid} = Map.fetch(ids, id)
    {:reply, {client_pid, id, name}, {ids, refs, id_name}}
  end

  def handle_call({:create_client, name}, _from, {ids, refs, id_name}) do
    {:ok, client_pid} = DynamicSupervisor.start_child(FS.ClientsSupervisor, FS.Clients)
    id = new_id(ids)
    ids = Map.put(ids, id, client_pid)

    ref = Process.monitor(client_pid)
    refs = Map.put(refs, ref, id)

    id_name = [{id, name}] ++ id_name
    {:reply, {client_pid, id}, {ids, refs, id_name}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {ids, refs, id_name}) do
    {id, refs} = Map.pop(refs, ref)
    ids = Map.delete(ids, id)
    id_name = List.keydelete(id_name, id, 0)
    {:noreply, {ids, refs, id_name}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defprotocol Gin do
    def get_id_name(id_or_name, id_name)
  end

  defimpl Gin, for: BitString do
    def get_id_name(name, id_name) do
      Enum.find(id_name, fn {_key, val} -> val == name end)
    end
  end

  defimpl Gin, for: Integer do
    def get_id_name(id, id_name) do
      Enum.find(id_name, fn {key, _val} -> key == id end)
    end
  end

  defp new_id(ids) do
    # !! Naive way !!
    # Should check for:
    # - duplicated entry !
    # - Strictly positive entry !
    # - choose the lowest available ??
    if ids == %{} do
      1000
    else
      Map.keys(ids)
      |> Enum.max()
      |> (fn x -> x + 1000 end).()
    end
  end
end
