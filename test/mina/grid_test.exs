defmodule Mina.GridTest do
  use ExUnit.Case
  doctest Mina.Grid

  describe "mine?/2" do
    test "it returns true when mine" do
      seed = Mina.Seed.build("test", 0.5)
      grid = Mina.Grid.new(seed, {0, 0}, 50)

      assert Mina.Grid.mine?(grid, {0, 0}) == true
    end

    test "it returns false when no mine" do
      seed = Mina.Seed.build("test", 0.5)
      grid = Mina.Grid.new(seed, {0, 0}, 50)

      assert Mina.Grid.mine?(grid, {0, 10}) == false
    end
  end

  describe "within?/2" do
    test "it returns true when pos within grid" do
      seed = Mina.Seed.build("test", 0.5)
      grid = Mina.Grid.new(seed, {0, 0}, 10)

      assert Mina.Grid.within?(grid, {0, 0}) == true
      assert Mina.Grid.within?(grid, {0, 9}) == true
      assert Mina.Grid.within?(grid, {9, 0}) == true
      assert Mina.Grid.within?(grid, {9, 9}) == true
    end

    test "it returns false when pos not within grid" do
      seed = Mina.Seed.build("test", 0.5)
      grid = Mina.Grid.new(seed, {0, 0}, 10)

      assert Mina.Grid.within?(grid, {-1, -1}) == false
      assert Mina.Grid.within?(grid, {-1, 10}) == false
      assert Mina.Grid.within?(grid, {10, -1}) == false
      assert Mina.Grid.within?(grid, {10, 10}) == false
    end
  end

  describe "adjacent_positions/1" do
    test "it returns adjacent positions" do
      [{0, 1}, {1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}] =
        Mina.Grid.adjacent_positions({0, 0})
    end
  end

  describe "flag/3" do
    test "it returns a flag move when a mine is flagged correctly" do
      seed = Mina.Seed.build("test", 0.5)
      grid = Mina.Grid.new(seed, {0, 0}, 50)

      {:ok, {moves, deferred}} = Mina.Grid.flag(grid, {0, 0}, 1)
      assert moves == %{{0, 0} => {{:mine, :flag}, 1}}
      assert deferred == []
    end

    test "it returns incorrect_flag when a mine is flagged incorrectly" do
      seed = Mina.Seed.build("test", 0.5)
      grid = Mina.Grid.new(seed, {0, 0}, 50)

      assert Mina.Grid.flag(grid, {0, 10}, 1) == {:error, :incorrect_flag}
    end
  end

  describe "reveal/3" do
    #    0 1 2 3 4 5 6 7 8 9
    #  0 X _ X X _ _ _ _ _ _
    #  1 _ X _ X _ _ X _ X _
    #  2 _ _ _ _ _ _ _ _ _ _
    #  3 _ _ X _ _ X _ _ _ _
    #  4 _ _ _ _ X _ X X _ _
    #  5 _ X _ _ X _ X _ _ _
    #  6 _ _ _ _ _ _ X X _ X
    #  7 _ _ _ _ X _ _ X _ _
    #  8 _ _ _ _ _ _ _ _ _ _
    #  9 _ _ _ X _ _ _ _ _ X

    test "it returns a hit when a mine is revealed" do
      seed = Mina.Seed.build("test", 0.5)
      grid = Mina.Grid.new(seed, {0, 0}, 10)

      {:ok, {moves, deferred}} = Mina.Grid.reveal(grid, {0, 0}, 1)
      assert moves == %{{0, 0} => {{:mine, :hit}, 1}}
      assert deferred == []
    end

    test "it returns a numbered tile when an empty tile with neighbouring mines is revealed" do
      seed = Mina.Seed.build("test", 0.2)
      grid = Mina.Grid.new(seed, {0, 0}, 10)

      {:ok, {moves, deferred}} = Mina.Grid.reveal(grid, {5, 4}, 1)
      assert moves == %{{5, 4} => {{:empty, 5}, 1}}
      assert deferred == []
    end

    test "it returns surrounding tiles when an empty tile with no neighbouring mines is revealed" do
      seed = Mina.Seed.build("test", 0.2)
      grid = Mina.Grid.new(seed, {0, 0}, 10)

      {:ok, {moves, deferred}} = Mina.Grid.reveal(grid, {1, 7}, 1)

      assert moves == %{
               {0, 6} => {{:empty, 3}, 1},
               {0, 7} => {{:empty, 1}, 1},
               {0, 8} => {{:empty, 1}, 1},
               {0, 9} => {{:empty, 1}, 1},
               {1, 6} => {{:empty, 1}, 1},
               {1, 7} => {{:empty, 0}, 1},
               {1, 8} => {{:empty, 0}, 1},
               {1, 9} => {{:empty, 1}, 1},
               {2, 6} => {{:empty, 1}, 1},
               {2, 7} => {{:empty, 0}, 1},
               {2, 8} => {{:empty, 1}, 1},
               {2, 9} => {{:empty, 3}, 1},
               {3, 6} => {{:empty, 2}, 1},
               {3, 7} => {{:empty, 1}, 1},
               {3, 8} => {{:empty, 2}, 1}
             }

      assert deferred == []
    end

    test "it returns surrounding tiles and deferred tiles when an empty tile with no neighbouring mines is revealed while bordering on another grid" do
      seed = Mina.Seed.build("test", 0.2)
      grid = Mina.Grid.new(seed, {0, 0}, 10)

      {:ok, {moves, deferred}} = Mina.Grid.reveal(grid, {0, 3}, 1)

      assert moves == %{
               {0, 2} => {{:empty, 2}, 1},
               {0, 3} => {{:empty, 0}, 1},
               {0, 4} => {{:empty, 2}, 1},
               {1, 2} => {{:empty, 2}, 1},
               {1, 3} => {{:empty, 1}, 1},
               {1, 4} => {{:empty, 2}, 1}
             }

      assert deferred == [{-1, 2}, {-1, 3}, {-1, 4}]
    end
  end
end
