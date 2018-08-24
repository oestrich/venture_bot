defmodule VentureBot.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {VentureBot.Client, []}
    ]

    opts = [strategy: :one_for_one, name: VentureBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
