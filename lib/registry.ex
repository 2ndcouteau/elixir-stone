defmodule FS.Registry do
  @moduledoc """
  Associate the bucket client_id to the bucket process
  and the bucket client_id to the clients names.
  """

  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Fetch registry informations from `id` or `name` stored in `server`.

  Returns a list of `{client_pid, id, name}` if the bucket exists, `:error` otherwise.
  """
  @spec fetch(GenServer.server(), integer() | String.t()) :: term()
  def fetch(server, id_or_name) do
    GenServer.call(server, {:fetch, id_or_name})
  end

  @doc """
  Create a entry/client in the bucket associated with the given `name` in `registry`.
  """
  @spec create_client(GenServer.server(), String.t()) :: term()
  def create_client(server, name) do
    GenServer.call(server, {:create_client, name})
  end

  @doc """
  Delete the client associated with the given `id` in the `registry`.
  """
  @spec delete_client(GenServer.server(), integer()) :: term()
  def delete_client(server, id) do
    GenServer.call(server, {:delete_client, id})
  end

  @doc """
  Stops the registry.
  """
  @spec stop(GenServer.server()) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  ## Server Callbacks

  @doc """
  Init the state of the Server

  ids = %{id, client_pid}
  refs = %{ref, id}
  id_name = [{id, name},]

  Where:
    `id` is a unique number to identified a client
    `client_pid` is the pid of a unique client process
    `name` is the name of a client. Several client can have the same name
    `ref` is a reference of the client process. ex: #=> #Reference<0.906660723.3006791681.40191>

  Return {:ok, {ids, refs, id_name}}
  """
  def init(:ok) do
    ids = %{}
    refs = %{}
    id_name = [{0, "bank"}]
    {:ok, {ids, refs, id_name}}
  end

  @doc """
  Fetch couple of {id, name} of client.s from the `client id` or the `client name`.
  Get informations from the registry process.

  Return only one couple if the entry is an `id` because it's unique.
  Can return several couple if the entry is a `name` because several clients can have the same name.
  """
  def handle_call({:fetch, id_or_name}, _from, {ids, refs, id_name}) do
    list = FS.Registry.Gin.get_id_name(id_or_name, id_name)
    new_list = merge_client_infos(list, [], ids)

    {:reply, new_list, {ids, refs, id_name}}
  end

  @doc """
  Create a new client entry in the registry.

  Return the new fresh `client_pid` process as well as a unique `id`.
  """
  def handle_call({:create_client, name}, _from, {ids, refs, id_name}) do
    {:ok, client_pid} = DynamicSupervisor.start_child(FS.ClientsSupervisor, FS.Clients)
    id = new_id(ids)
    ids = Map.put(ids, id, client_pid)

    ref = Process.monitor(client_pid)
    refs = Map.put(refs, ref, id)

    id_name = [{id, name}] ++ id_name
    {:reply, {client_pid, id}, {ids, refs, id_name}}
  end

  @doc """
  Delete client from the registry from its unique `id`.

  Return the `client_pid` stopped and the `id` deleted.
  """
  def handle_call({:delete_client, id}, _from, {ids, refs, id_name}) do
    {ref, _id} = Enum.find(refs, fn {_key, value} -> value == id end)
    {id, refs} = Map.pop(refs, ref)
    {client_pid, ids} = Map.pop(ids, id)
    id_name = List.keydelete(id_name, id, 0)
    DynamicSupervisor.terminate_child(FS.ClientsSupervisor, client_pid)
    {:reply, {client_pid, id}, {ids, refs, id_name}}
  end

  @doc """
  Delete from registry the references of a client process which has been kill unexpectedly.


  """
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
    @doc """
    Get Id or Name (GIN)

    Return a :: list() []

    Return the registry information for an `ID`.
    or
    Return one or various informations for a `name`.
    Several clients can have the same `name`.
    """
    # @fallback_to_any true
    @spec get_id_name(String.t() | integer(), map()) :: list()
    def get_id_name(id_or_name, id_name)
  end

  defimpl Gin, for: BitString do
    @doc "Return the infos of the client.s from their `name`"
    @spec get_id_name(String.t(), map()) :: list()
    def get_id_name(name, id_name) do
      Enum.filter(id_name, fn {_key, value} -> value == name end)
    end
  end

  defimpl Gin, for: Integer do
    @doc "Return the infos of the client from his `id`"
    @spec get_id_name(integer(), map()) :: list()
    def get_id_name(id, id_name) do
      Enum.filter(id_name, fn {key, _value} -> key == id end)
    end
  end

  # @spec merge_client_infos(list(), list(), map()) :: list()
  defp merge_client_infos(list, new_list, _ids) when list == [] do
    new_list
  end

  @spec merge_client_infos(list(), list(), map()) :: list()
  defp merge_client_infos(list, new_list, ids) do
    {{key, value}, list} = List.pop_at(list, 0)
    {_, client_pid} = Map.fetch(ids, key)
    merge_client_infos(list, [{client_pid, key, value}] ++ new_list, ids)
  end

  @spec new_id(map()) :: integer()
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
