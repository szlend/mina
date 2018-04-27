defmodule Mina.Grid do
  defstruct [:seed, :offset, :size, :moves]

  @type t :: %Mina.Grid{
          seed: Mina.Seed.t(),
          offset: abs_pos,
          size: pos_integer,
          moves: moves
        }
  @type abs_pos :: {integer, integer}
  @type rel_pos :: {integer, integer}
  @type moves :: %{optional(rel_pos) => move}
  @type move :: {move_type, player_id}
  @type move_type :: {:mine, :hit} | {:mine, :flag} | {:empty, 0..8}
  @type player_id :: pos_integer

  @type action :: :reveal | :flag
  @type action_result ::
          {:ok, {moves, [rel_pos]}}
          | {:error, :already_cleared}
          | {:error, :incorrect_flag}

  @spec new(Mina.Seed.t(), abs_pos, pos_integer) :: t
  def new(seed, offset, size) do
    %Mina.Grid{seed: seed, offset: offset, size: size, moves: %{}}
  end

  @spec mine?(t, rel_pos) :: boolean
  def mine?(%{offset: {offset_x, offset_y}, seed: seed}, {x, y}) do
    :erlang.phash2({seed.key, offset_x + x, offset_y + y}, seed.range) < seed.difficulty
  end

  @spec within?(t, rel_pos) :: boolean
  def within?(%{size: size}, {x, y}) do
    x in 0..(size - 1) and y in 0..(size - 1)
  end

  @spec adjacent_positions(rel_pos) :: [rel_pos]
  def adjacent_positions({x, y}) do
    [
      {x + 0, y + 1},
      {x + 1, y + 1},
      {x + 1, y + 0},
      {x + 1, y - 1},
      {x + 0, y - 1},
      {x - 1, y - 1},
      {x - 1, y + 0},
      {x - 1, y + 1}
    ]
  end

  @spec action(t, action, rel_pos, player_id) :: action_result
  def action(grid, :flag, pos, player_id), do: flag(grid, pos, player_id)
  def action(grid, :reveal, pos, player_id), do: reveal(grid, pos, player_id)

  @spec flag(t, rel_pos, player_id) :: action_result
  def flag(grid, pos, player_id) do
    if grid.moves[pos] do
      {:error, :already_cleared}
    else
      do_flag(grid, pos, player_id)
    end
  end

  @spec do_flag(t, rel_pos, player_id) :: action_result
  defp do_flag(grid, pos, player_id) do
    if mine?(grid, pos) do
      moves = %{pos => {{:mine, :flag}, player_id}}
      {:ok, {moves, []}}
    else
      {:error, :incorrect_flag}
    end
  end

  @spec reveal(t, rel_pos, player_id) :: action_result
  def reveal(grid, pos, player_id) do
    if grid.moves[pos] do
      {:error, :already_cleared}
    else
      do_reveal(grid, pos, player_id)
    end
  end

  @spec do_reveal(t, rel_pos, player_id) :: action_result
  defp do_reveal(grid, pos, player_id) do
    if mine?(grid, pos) do
      moves = %{pos => {{:mine, :hit}, player_id}}
      {:ok, {moves, []}}
    else
      {moves, deferred} = do_reveal_empty(grid, pos, player_id, %{}, MapSet.new())
      {:ok, {moves, Enum.to_list(deferred)}}
    end
  end

  @spec do_reveal_empty(t, rel_pos, player_id, moves, MapSet.t(rel_pos)) ::
          {moves, MapSet.t(rel_pos)}
  defp do_reveal_empty(grid, pos, player_id, moves, deferred) do
    if grid.moves[pos] || moves[pos] do
      {moves, deferred}
    else
      adjacent = adjacent_positions(pos)
      count = Enum.count(adjacent, &mine?(grid, &1))
      moves = Map.put(moves, pos, {{:empty, count}, player_id})

      if count == 0 do
        {local, neighbour} = Enum.split_with(adjacent, &within?(grid, &1))
        deferred = MapSet.union(deferred, MapSet.new(neighbour))

        Enum.reduce(local, {moves, deferred}, fn pos, {moves, deferred} ->
          do_reveal_empty(grid, pos, player_id, moves, deferred)
        end)
      else
        {moves, deferred}
      end
    end
  end
end
