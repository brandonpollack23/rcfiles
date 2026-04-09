IEx.configure(
  auto_reload: true,
  colors: [
    syntax_colors: [
      number: :light_yellow,
      atom: :light_cyan,
      string: :light_black,
      boolean: :red,
      nil: [:magenta, :bright]
    ],
    ls_directory: :cyan,
    ls_device: :yellow,
    doc_code: :green,
    doc_inline_code: :magenta,
    doc_headings: [:cyan, :underline],
    doc_title: [:cyan, :bright, :underline]
  ],
  default_prompt: "[%prefix] %counter>",
  alive_prompt: "[%prefix] %node %counter>",
  inspect: [pretty: true, limit: :infinity, width: 80]
)

defmodule History do
  def history do
    :group_history.load()
    # drop the history call itself
    |> Enum.drop(1)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {cmd, idx} -> "#{idx}) #{cmd}" end)
    |> Enum.join()
    |> IO.puts()

    IEx.dont_display_result()
  end

  def history(number) when is_integer(number) and number > 0 do
    # subtract one for this command
    hist = :group_history.load() |> Enum.drop(1)
    l = hist |> length()

    command = hist |> Enum.at(l - number - 1)

    Code.eval_string(command)

    IEx.dont_display_result()
  end

  def history(number) when is_integer(number) and number < 0 do
    hist = :group_history.load() |> Enum.drop(2)
    l = hist |> length()
    history(l + number)
  end
end

import History
