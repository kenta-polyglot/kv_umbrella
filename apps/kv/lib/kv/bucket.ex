defmodule KV.Bucket do
  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  def delete(bucket, key) do
    # Map.pop returns and removes all values associated with key in the map
    # Map.pop(%{a: 1}, :a)
    # => {1, %{}}

    # Agent.get_and_update/3 spec is below:
    # get_and_update(agent, (state -> {a, state}), timeout) :: a when a: var
    Agent.get_and_update(bucket, &Map.pop(&1, key))

    # We should avoid long action performed on the server. example is below:
    # :timer.sleep(1000) # puts client to sleep
    # Agent.get_and_update(bucket, fn dict ->
    #   :timer.sleep(1000) # puts server to sleep
    #   Map.pop(dict, key)
    # end)
  end
end