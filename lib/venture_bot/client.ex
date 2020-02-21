defmodule VentureBot.Client do
  use GenServer

  require Logger

  alias VentureBot.Client.Bot
  alias VentureBot.Parser

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def push(pid, string) do
    send(pid, {:send, string})
  end

  def init([counter]) do
    Logger.info("Starting bot #{counter}")
    {:ok, %{active: false, name: nil, counter: counter}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    {:ok, socket} = :gen_tcp.connect('localhost', 4444, [:binary, {:packet, 0}])
    {:noreply, Map.put(state, :socket, socket)}
  end

  def handle_info({:tcp, _port, data}, state) do
    string = data |> Parser.clean_string()

    {:ok, state} = Bot.process(state, string)

    {:noreply, state}
  end

  def handle_info({:send, string}, state) do
    Logger.debug("[#{state.name}] Sending: " <> string)
    :gen_tcp.send(state.socket, string <> "\n")
    {:noreply, state}
  end

  defmodule Bot do
    @exits_regex ~r/Exits: (?<exits>[\w\(\), ]+)\n/

    alias VentureBot.Client

    def process(state = %{active: false}, string) do
      cond do
        account_name_prompt?(string) ->
          name = random_name()
          Client.push(self(), name)
          {:ok, %{state | name: name}}

        account_password_prompt?(string) ->
          Client.push(self(), "password")
          {:ok, state}

        character_name_prompt?(string) ->
          Logger.info("Bot #{state.counter} signed in")
          Client.push(self(), state.name)
          {:ok, %{state | active: true}}

        true ->
          {:ok, state}
      end
    end

    def process(state = %{active: true}, string) do
      case exits?(string) do
        true ->
          captures = Regex.named_captures(@exits_regex, string)

          case captures do
            %{"exits" => exits} ->
              exit =
                exits
                |> String.split(" ")
                |> Enum.map(&String.trim/1)
                |> Enum.shuffle()
                |> List.first()

              delay = Enum.random(3_500..7_000)
              Process.send_after(self(), {:send, exit}, delay)

            _ ->
              delay = Enum.random(3_500..7_000)
              Process.send_after(self(), {:send, "look"}, delay)
          end

          {:ok, state}

        false ->
          {:ok, state}
      end
    end

    defp account_name_prompt?(string) do
      Regex.match?(~r/What is your name\?/, string)
    end

    defp account_password_prompt?(string) do
      Regex.match?(~r/Password:/, string)
    end

    defp character_name_prompt?(string) do
      Regex.match?(~r/What is your character name\?/, string)
    end

    defp exits?(string) do
      Regex.match?(~r/Exits:/, string)
    end

    defp random_name() do
      UUID.uuid4()
      |> String.slice(0..11)
      |> String.replace("-", "")
    end
  end
end
