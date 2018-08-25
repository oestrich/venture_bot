defmodule VentureBot.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {VentureBot.Supervisor, []},
      {VentureBot.Monitor, []}
    ]

    opts = [strategy: :one_for_one, name: VentureBot.AppSupervisor]
    Supervisor.start_link(children, opts)
  end
end
