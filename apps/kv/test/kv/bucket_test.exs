# We don’t need to explicitly stop the agent because it is linked to the test process and 
# the agent is shut down automatically once the test finishes. 
# This will always work unless the process is named.

# Also note that we passed the async: true option to ExUnit.Case. 
# This option makes this test case run in parallel with other test cases that set up the :async option. 
# This is extremely useful to speed up our test suite by using multiple cores in our machine. 

defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  # setup/1 callback runs before every test, in the same process as the test itself.
  setup do
    {:ok, bucket} = KV.Bucket.start_link
    {:ok, bucket: bucket}
  end

  # `bucket` is now the bucket from the setup block
  # we calle it `test context`
  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end
end