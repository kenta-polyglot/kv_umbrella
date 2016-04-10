# We don’t need to explictly shut down the registry 
# because it will receive a :shutdown signal when our test finishes.

defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  # setup/2 may also receive the test context, 
  # the context includes some default keys, like :case, :test, :file and :line. 
  # We have used context.test as a shortcut to spawn a registry with the same name of the test currently running.
  setup context do
    {:ok, _} = KV.Registry.start_link(context.test)
    {:ok, registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)

    # An easy way to ensure :DOWN message was processed is by sending a synchronous request to the registry: 
    # because messages are processed in order, if the registry replies to a request sent after the Agent.stop call, 
    # it means it the :DOWN message has been processed.
    # Do a call to ensure the registry processed the :DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Kill the bucket and wait for the notification
    Process.exit(bucket, :shutdown)

    # Wait until the bucket is dead
    #  Opposite to Agent.stop/1, Process.exit/2 is an asynchronous operation, 
    # therefore we cannot simply query KV.Registry.lookup/2 right after sending the exit signal 
    # because there will be no guarantee the bucket will be dead by then. 
    # To solve this, we also monitor the bucket during test and only query the registry once we are sure it is DOWN, avoiding race conditions.
    ref = Process.monitor(bucket)
    assert_receive {:DOWN, ^ref, _, _, _}

    # Do a call to ensure the registry processed the DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end