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
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  def handle_call({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:reply, {names, refs}}
    else
      {:ok, pid} = FS.Bucket.start_link([])
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:reply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

#   ## Server Callbacks
#
#   def init(:ok) do
#     {:ok, %{}}
#   end
#
#   def handle_call({:lookup, name}, _from, names) do
#     {:reply, Map.fetch(names, name), names}
#   end
#
#   def handle_cast({:create, name}, names) do
#     if Map.has_key?(names, name) do
#       {:noreply, names}
#     else
#       {:ok, bucket} = FS.Bucket.start_link([])
#       {:noreply, Map.put(names, name, bucket)}
#     end
#   end
# end
