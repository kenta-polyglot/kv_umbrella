# This supervisors is intended to group and create bucket.
# So it need not to restart bucket process.

defmodule KV.Bucket.Supervisor do
  use Supervisor

  # A simple module attribute that stores the supervisor name
  @name KV.Bucket.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_bucket do
    Supervisor.start_child(@name, [])
  end

  def init(:ok) do
    children = [
      # worker(KV.Bucket, []) will start process like below:
      # KV.Bucket.start_link

      # we are marking the worker as :temporary. This means that if the bucket dies, it won’t be restarted! 
      worker(KV.Bucket, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end