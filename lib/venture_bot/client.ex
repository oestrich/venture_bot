defmodule VentureBot.Client do
  use GenServer

  require Logger

  alias VentureBot.Client.Bot
  alias VentureBot.Parser

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    Logger.info("Starting bot")
    {:ok, %{active: false}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    {:ok, socket} = :gen_tcp.connect('localhost', 5555, [:binary, {:packet, 0}])
    {:noreply, Map.put(state, :socket, socket)}
  end

  def handle_info({:tcp, _port, data}, state) do
    string = data |> Parser.clean_string()

    {:ok, state} = Bot.process(state, string)

    {:noreply, state}
  end

  def handle_info({:send, string}, state) do
    :gen_tcp.send(state.socket, string <> "\n")

    {:noreply, state}
  end

  defmodule Bot do
    @exits_regex ~r/Exits: (?<exits>[\w, ]+)\n/

    def process(state = %{active: false}, string) do
      IO.puts(string)

      cond do
        login_name?(string) ->
          Logger.info("Logging in")
          :gen_tcp.send(state.socket, "player\n")
          {:ok, state}

        login_link?(string) ->
          Logger.info("Found the login link")
          {:ok, state}

        press_enter?(string) ->
          Logger.info("Sending enter")
          :gen_tcp.send(state.socket, "\n")
          {:ok, %{state | active: true}}

        true ->
          {:ok, state}
      end
    end

    def process(state = %{active: true}, string) do
      IO.puts string

      case exits?(string) do
        true ->
          Logger.info("Found exits")
          [_, exits] = Regex.run(@exits_regex, string)
          exit =
            exits
            |> String.split(",")
            |> Enum.map(&String.trim/1)
            |> Enum.shuffle()
            |> List.first()

          Process.send_after(self(), {:send, exit}, 1500)

          {:ok, state}

        false ->
          {:ok, state}
      end
    end

    defp login_name?(string) do
      Regex.match?(~r/your player name/, string)
    end

    defp login_link?(string) do
      Regex.match?(~r/http:\/\/.+\n/, string)
    end

    defp press_enter?(string) do
      Regex.match?(~r/\[Press enter to continue\]/, string)
    end

    defp exits?(string) do
      Regex.match?(@exits_regex, string)
    end
  end
end
