defmodule FS.Clients do
  use Agent, restart: :temporary

  @doc """
  Bucket implementation.
  """
  def start_link(_opt) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
    Get a `value` from `bucket` by `key`
  """
  def get(pid, key) do
    Agent.get(pid, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(pid, key, value) do
    Agent.update(pid, &Map.put(&1, key, value))
  end

  @doc """
  Deletes `key` from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(pid, key) do
    Agent.get_and_update(pid, &Map.pop(&1, key))
  end
end
