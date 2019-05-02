# """
# iex > {:ok, agent} = Agent.start_link(fn -> [] end)
# {:ok, PID<0.57.0>}
# iex > Agent.update(agent, fn list -> ["eggs" | list] end)
# :ok
# iex > Agent.get(agent, fn list -> list end)
# ["eggs"]
# iex > Agent.stop(agent)
# :ok
# """
#
# defmodule KV.BucketTest do
#   use ExUnit.Case, async: true
#
#   setup do
#     {:ok, bucket} = KV.Bucket.start_link([])
#     %{bucket: bucket}
#   end
#
#   test "stores values by key", %{bucket: bucket} do
#     assert KV.Bucket.get(bucket, "milk") == nil
#
#     KV.Bucket.put(bucket, "milk", 3)
#     assert KV.Bucket.get(bucket, "milk") == 3
#   end
# end
#
# ## KV.REGISTRY
# def start_link(opts) do
#   GenServer.start_link(__MODULE__, :ok, opts)
# end
#
# defmodule KV.RegistryTest do
#   use ExUnit.Case, async: true
#
#   setup do
#     registry = start_supervised!(KV.Registry)
#     %{registry: registry}
#   end
#
#   test "spawns buckets", %{registry: registry} do
#     assert KV.Registry.lookup(registry, "shopping") == :error
#
#     KV.Registry.create(registry, "shopping")
#     assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
#
#     KV.Bucket.put(bucket, "milk", 1)
#     assert KV.Bucket.get(bucket, "milk") == 1
#   end
# end
#
# """
# 1 - Start Registry
#   return{:ok, PID} //
# 2 - Create a Bucket and put his name in the Regitry
#   return{:ok, bucket} // bucket == PID
#
#
# """
#
#
# If I want to save an information I have to:
#
# 1) Start the Registry
#   Start by he supervisor
# 2) Create a Bucket (an Agent which will save the information/ a memory space)
#
# 3) Get the Pid of the bucket with a lookup
#   - This is because the Registry host all the buckets
# 4) Use the Bucket method to save an information
#
# 5) You can retreive information by using a bucket method.
#
#

# {_, registry} = GenServer.start_link(FS.Registry, :ok, [])
# FS.Registry.create(registry, "students")
# FS.Registry.lookup(registry, "students")
