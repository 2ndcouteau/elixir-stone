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
  def fetch(server, id_or_name) do
    GenServer.call(server, {:fetch, id_or_name})
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
  def handle_call({:fetch, id_or_name}, _from, {ids, refs, id_name}) do
    list = FS.Registry.Gin.get_id_name(id_or_name, id_name)
    new_list = merge_client_infos(list, [], ids)

    {:reply, new_list, {ids, refs, id_name}}
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
      Enum.filter(id_name, fn {_key, value} -> value == name end)
    end
  end

  defimpl Gin, for: Integer do
    def get_id_name(id, id_name) do
      Enum.filter(id_name, fn {key, _value} -> key == id end)
    end
  end

  defp merge_client_infos(list, new_list, _ids) when list == [] do
    new_list
  end

  defp merge_client_infos(list, new_list, ids) do
    {{key, value}, list} = List.pop_at(list, 0)
    {_, client_pid} = Map.fetch(ids, key)
    merge_client_infos(list, [{client_pid, key, value}] ++ new_list, ids)
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
