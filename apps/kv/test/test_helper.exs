# With the test properly tagged, we can now check if the node is alive on the network and, 
# if not, we can exclude all distributed tests. 
# Open up test/test_helper.exs inside the :kv application and add the following:
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
