defmodule VentureBot.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(counter) do
    DynamicSupervisor.start_child(__MODULE__, {VentureBot.Client, [counter]})
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
