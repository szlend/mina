defmodule Mina.Grid.Worker do
  use GenServer, restart: :temporary

  def start_link(extra_args, args) do
    start_link(extra_args ++ args)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    seed = Keyword.fetch!(args, :seed)
    offset = Keyword.fetch!(args, :offset)
    size = Keyword.fetch!(args, :size)
    grid = Mina.Grid.new(seed, offset, size)
    {:ok, %{grid: grid}}
  end

  def fetch(offset) do
    name = {:grid, offset}
    supervisor = Mina.Grid.Supervisor
    args = [offset: offset]

    with :undefined <- Swarm.whereis_name(name),
         {:ok, pid} <- Swarm.register_name(name, supervisor, :start_child, [args]) do
      Swarm.join(:grid, pid)
      {:ok, pid}
    else
      pid when is_pid(pid) -> {:ok, pid}
      {:error, {:already_registered, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  def list() do
    Swarm.members(:grid)
  end
end
