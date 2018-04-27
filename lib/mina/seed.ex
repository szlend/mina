defmodule Mina.Seed do
  defstruct [:key, :difficulty, :range]

  @type t :: %Mina.Seed{key: String.t(), difficulty: float, range: pos_integer}
  @range 100_000

  def build(key, difficulty) when difficulty >= 0.0 and difficulty <= 1.0 do
    %Mina.Seed{key: key, difficulty: difficulty * @range, range: @range}
  end
end
