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
