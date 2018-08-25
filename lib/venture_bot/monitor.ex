defmodule VentureBot.Monitor do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    Logger.info("Starting the monitor")
    Process.send_after(self(), :kick_off, 1_000)
    {:ok, %{}}
  end

  def handle_info(:kick_off, state) do
    Logger.info("Kicking off clients")

    Enum.each(1..1000, fn i ->
      Process.send_after(self(), :start_child, i * 3000)
    end)

    {:noreply, state}
  end

  def handle_info(:start_child, state) do
    VentureBot.Supervisor.start_child()
    {:noreply, state}
  end
end
