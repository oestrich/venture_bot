defmodule VentureBot.Monitor do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def kick_off(count \\ 100) do
    GenServer.call(__MODULE__, {:kick_off, count})
  end

  def init(_) do
    Logger.info("Starting the monitor")
    Process.send_after(self(), {:kick_off, 100}, 1_000)
    {:ok, %{}}
  end

  def handle_cast({:kick_off, count}, state) do
    handle_info({:kick_off, count}, state)
  end

  def handle_info({:kick_off, count}, state) do
    Logger.info("Kicking off clients")

    Enum.each(1..count, fn i ->
      Process.send_after(self(), :start_child, i * 1000)
    end)

    {:noreply, state}
  end

  def handle_info(:start_child, state) do
    VentureBot.Supervisor.start_child()
    {:noreply, state}
  end
end
