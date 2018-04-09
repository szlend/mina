defmodule Mina.Repo do
  use Ecto.Repo, otp_app: :mina

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  @impl true
  def init(_, opts) do
    if url = System.get_env("DATABASE_URL") do
      {:ok, Keyword.put(opts, :url, url)}
    else
      {:ok, opts}
    end
  end
end
