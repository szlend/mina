defmodule Mina.Grid.Debug do
  def dump_mines(grid) do
    generate_grid(grid, fn pos ->
      if Mina.Grid.mine?(grid, pos), do: ".", else: "_"
    end)
  end

  def dump_moves(grid) do
    generate_grid(grid, fn pos ->
      case grid.moves[pos] do
        {{:mine, :flag}, _} -> "F"
        {{:mine, :hit}, _} -> "X"
        {{:empty, n}, _} -> "#{n}"
        nil -> if Mina.Grid.mine?(grid, pos), do: ".", else: "_"
      end
    end)
  end

  defp generate_grid(grid, fun) do
    range = 0..(grid.size - 1)

    Enum.map(range, fn y ->
      range
      |> Enum.map(fn x -> fun.({x, y}) end)
      |> Enum.join(" ")
    end)
    |> Enum.join("\n")
  end
end
