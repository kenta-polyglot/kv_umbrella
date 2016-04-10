defmodule KV.Registry do
  use GenServer

  ## Client API

  # Once the server is started, it calls the init/1 function in the given module.
  # If the server is successfully created and initialized, the function returns {:ok, pid}
  # def start_link do
  def start_link(name) do
    # GenServer.start_link(__MODULE__, :ok, name: name)
    # 1. Pass the name to GenServer's init
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def lookup(server, name) when is_atom(server) do
    # 2. Lookup is now done directly in ETS, without accessing the server
    case :ets.lookup(server, name) do
      [{^name, bucket}] -> {:ok, bucket}
      [] -> :error
    end
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  def stop(server) do
    GenServer.stop(server)
  end

  ## Server Callbacks

  def init(table) do
    # 3. We have replaced the names map by the ETS table
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs  = %{}
    {:ok, {names, refs}}
  end

  # handle_call/3 spec is:
  # handle_call(request :: term, from, state :: term) ::
  # {:reply, reply, new_state} |
  # {:reply, reply, new_state, timeout | :hibernate} |
  # {:noreply, new_state} |
  # {:noreply, new_state, timeout | :hibernate} |
  # {:stop, reason, reply, new_state} |
  # {:stop, reason, new_state} when reply: term, new_state: term, reason: term
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, _pid} ->
        {:noreply, {names, refs}}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        # {:noreply, {names, refs}}
        {:reply, pid, {names, refs}}
    end
  end

  # handle_info/2 must be used for all other messages a server may receive that are not sent via GenServer.call/2 or GenServer.cast/2, 
  # including regular messages sent with send/2. The monitoring :DOWN messages are a perfect example of this.
  # message will passed like below:
  # {:DOWN, #Reference<0.0.3.169>, :process, #PID<0.107.0>, :normal}
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    # 6. Delete from the ETS table instead of the map
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  # required. without this catch-all clause, registry will be crashed.
  def handle_info(_msg, state) do
    {:noreply, state}
  end  
end