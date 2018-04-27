defmodule Mina.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    seed = Mina.Seed.build("test", 0.2)
    size = 50

    children = [
      {Mina.Repo, []},
      {Mina.Grid.Supervisor, [seed: seed, size: size]},
      {MinaWeb.Endpoint, []}
    ]

    opts = [strategy: :one_for_one, name: Mina.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MinaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
