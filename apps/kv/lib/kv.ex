defmodule KV do
  use Application

  # This is an application callback function. This is a function that will be invoked when the application starts. 
  # (defined in mix.exs)
  # The function must return a result of {:ok, pid}, where pid is the process identifier of a supervisor process.
  def start(_type, _args) do
    KV.Supervisor.start_link
  end
end
