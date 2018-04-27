defmodule Mina.Grid.Supervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    seed = Keyword.fetch!(args, :seed)
    size = Keyword.fetch!(args, :size)
    args = [seed: seed, size: size]
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [args])
  end

  def start_child(args) do
    DynamicSupervisor.start_child(__MODULE__, {Mina.Grid.Worker, args})
  end
end
