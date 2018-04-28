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
      pid
    else
      pid when is_pid(pid) -> pid
      {:error, {:already_registered, pid}} -> pid
    end
  end

  def list() do
    Swarm.members(:grid)
  end

  def handle_cast({:flag, pos, player_id}, state) do
    IO.inspect({:flag, pos, player_id})

    state =
      case flag_pos(state, pos, player_id) do
        {:ok, moves} -> %{state | moves: Map.merge(state.moves, moves)}
        {:error, _reason} -> state
      end

    {:noreply, state}
  end

  def handle_cast({:reveal, pos, player_id}, state) do
    IO.inspect({:reveal, pos, player_id})

    state =
      case reveal_pos(state, pos, player_id) do
        {:ok, state} -> state
        {:error, _reason} -> state
      end

    {:noreply, state}
  end

  def handle_cast({:continue_reveal, deferred, player_id}, state) do
    IO.inspect({:continue_reveal, deferred, player_id})

    state =
      Enum.reduce(deferred, state, fn pos, state ->
        case reveal_pos(state, pos, player_id) do
          {:ok, state} -> state
          {:error, _reason} -> state
        end
      end)

    {:noreply, state}
  end

  defp flag_pos(state, pos, player_id) do
    with {:ok, {moves, []}} <- Mina.Grid.flag(state.grid, pos, player_id) do
      state = update_in(state.grid.moves, &Map.merge(&1, moves))
      {:ok, state}
    end
  end

  defp reveal_pos(state, pos, player_id) do
    with {:ok, {moves, deferred}} <- Mina.Grid.reveal(state.grid, pos, player_id) do
      offset_fun = fn {_, offset} -> offset end
      pos_fun = fn {pos, _} -> pos end
      deferred_offset = Mina.Grid.offset_deferred(state.grid, deferred)

      for {offset, pos_list} <- Enum.group_by(deferred_offset, offset_fun, pos_fun) do
        GenServer.cast(fetch(offset), {:continue_reveal, pos_list, player_id})
      end

      state = update_in(state.grid.moves, &Map.merge(&1, moves))
      {:ok, state}
    end
  end
end
