defmodule KV.Supervisor do
  use Supervisor

  def start_link do
    # spec is:
    # on_start ::
    # {:ok, pid} |
    # :ignore |
    # {:error, {:already_started, pid} | {:shutdown, term} | term}
    # start_link(module, term) :: on_start
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      # worker(KV.Registry, [KV.Registry]) will start process like below:
      # KV.Registry.start_link(KV.Registry)

      # start_link/1 returns {:ok, pid}, and first argument is the process name.
      # So other process can access registry without knowing the pid of the registry. 

      # This is useful because a supervised process might crash, 
      # in which case its pid will change when the supervisor restarts it. 
      # By using a name, we can guarantee the newly started process will register itself under the same name, 
      # without a need to explicitly fetch the latest pid.
      worker(KV.Registry, [KV.Registry]),

      # By default, the function start_link is invoked on the given module
      # in this case,
      # KV.Bucket.Supervisor.start_link
      supervisor(KV.Bucket.Supervisor, []),
      supervisor(Task.Supervisor, [[name: KV.RouterTasks]])
    ]

    # :one_for_one means that if a child dies, it will be the only one restarted. 
    # supervise(children, strategy: :one_for_one)

    # :rest_for_one -> If the registry worker crashes, both registry and bucket supervisor is restarted. 
    # If the bucket supervisor crashes, only the bucket supervisor is restarted.
    supervise(children, strategy: :rest_for_one)
  end
end