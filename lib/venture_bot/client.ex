defmodule VentureBot.Client do
  use GenServer

  require Logger

  alias VentureBot.Client.Bot
  alias VentureBot.Parser

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def push(pid, string) do
    send(pid, {:send, string})
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
    Logger.info("Sending: " <> string)
    :gen_tcp.send(state.socket, string <> "\n")
    {:noreply, state}
  end

  defmodule Bot do
    @exits_regex ~r/Exits: (?<exits>[\w\(\), ]+)\n/
    @races_regex ~r/(?<options>options are:(?:\n\t- \w+)+)/

    alias VentureBot.Client

    def process(state = %{active: false}, string) do
      #IO.puts(string)

      cond do
        login_name?(string) ->
          Logger.info("Logging in")
          Client.push(self(), "create")
          {:ok, state}

        login_link?(string) ->
          Logger.info("Found the login link")
          {:ok, state}

        create_name_prompt?(string) ->
          Logger.info("Picking a name")
          Client.push(self(), random_name())
          {:ok, state}

        create_races_prompt?(string) ->
          Logger.info("Picking a race")
          captures = Regex.named_captures(@races_regex, string)
          [_ | options] = String.split(captures["options"], "\n")

          race =
            options
            |> Enum.map(&String.replace(&1, "-", ""))
            |> Enum.map(&String.trim/1)
            |> Enum.shuffle()
            |> List.first

          Client.push(self(), race)

          {:ok, state}

        create_email_prompt?(string) ->
          Logger.info("Skipping email")
          Client.push(self(), "")
          {:ok, state}

        create_password_prompt?(string) ->
          Logger.info("Sending a password")
          Client.push(self(), "password")
          {:ok, state}

        press_enter?(string) ->
          Logger.info("Sending enter")
          Client.push(self(), "")
          {:ok, %{state | active: true}}

        true ->
          {:ok, state}
      end
    end

    def process(state = %{active: true}, string) do
      #IO.puts string

      case exits?(string) do
        true ->
          Logger.info("Found exits")
          [_, exits] = Regex.run(@exits_regex, string)
          exit =
            exits
            |> String.split(",")
            |> Enum.map(&String.replace(&1, "(closed)", ""))
            |> Enum.map(&String.replace(&1, "(open)", ""))
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

    defp create_name_prompt?(string) do
      Regex.match?(~r/\nName:/, string)
    end

    defp create_races_prompt?(string) do
      Regex.match?(@races_regex, string)
    end

    defp create_email_prompt?(string) do
      Regex.match?(~r/Email \(optional, enter for blank\):/, string)
    end

    defp create_password_prompt?(string) do
      Regex.match?(~r/\nPassword:/, string)
    end

    defp press_enter?(string) do
      Regex.match?(~r/\[Press enter to continue\]/, string)
    end

    defp exits?(string) do
      Regex.match?(@exits_regex, string)
    end

    defp random_name() do
      UUID.uuid4()
      |> String.slice(0..11)
      |> String.replace("-", "")
    end

    defp random_password() do
      UUID.uuid4()
    end
  end
end
