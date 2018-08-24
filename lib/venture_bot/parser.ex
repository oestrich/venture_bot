defmodule VentureBot.Parser do
  @iac 255
  @will 251
  @telnet_do 253

  @ga 249

  def clean_string(data) do
    data
    |> parse_data()
    |> strip_color()
  end

  defp parse_data(data) do
    data
    |> remove_iac([])
    |> Enum.reverse()
    |> to_string()
  end

  defp strip_color(string) do
    string
    |> String.replace(~r/\e\[\d+m/, "")
    |> String.replace(~r/\e\[\d+;\d+;\d+m/, "")
  end

  defp remove_iac(<<>>, acc), do: acc

  defp remove_iac(<<@iac, @will, _option :: size(8), rest :: binary()>>, acc) do
    remove_iac(rest, acc)
  end

  defp remove_iac(<<@iac, @telnet_do, _option :: size(8), rest :: binary()>>, acc) do
    remove_iac(rest, acc)
  end

  defp remove_iac(<<@iac, @ga, rest :: binary()>>, acc) do
    remove_iac(rest, acc)
  end

  defp remove_iac(<<bit :: size(8), rest :: binary()>>, acc) do
    remove_iac(rest, [bit | acc])
  end
end
