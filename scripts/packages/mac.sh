# The Mac: common and homebrew (common.sh), then these. Formulae from other
# taps are named <user>/<tap>/<formula>; brew taps them itself.

brew=(
  # GNU and newer versions of what macOS ships
  bash         # A current Bash (macOS ships 3.2)
  binutils     # GNU binary tools (objdump, readelf...)
  coreutils    # GNU file, shell and text utilities (g-prefixed)
  diffutils    # GNU diff, cmp and friends
  file-formula # file(1), newer than macOS's
  findutils    # GNU find, locate and xargs
  gawk         # GNU awk
  gnu-sed      # GNU sed (gsed)
  gnu-tar      # GNU tar (gtar)
  gnu-which    # GNU which
  gpatch       # GNU patch
  grep         # GNU grep (ggrep)
  gzip         # GNU gzip
  less         # A current less pager
  make         # GNU make (gmake)
  openssh      # A current OpenSSH (with FIDO key support)
  rsync        # A current rsync
  screen       # Terminal multiplexer
  telnet       # Telnet client

  # Build tools and compilers
  autoconf     # Generates configure scripts
  automake     # Generates Makefile.in files for autoconf
  binaryen     # Compiler and toolchain infrastructure for WebAssembly
  cmake        # Cross-platform open-source make system
  gcc          # GNU compiler collection
  libtool      # Generic library support script, for autoconf builds
  lld          # LLVM linker
  pkgconf      # pkg-config: compiler and linker flags for libraries
  wasm-bindgen # Rust and JavaScript interop for WebAssembly
  wasm-pack    # Builds Rust-generated WebAssembly packages

  # Languages, runtimes and their tools
  deno          # A secure runtime for JavaScript and TypeScript
  ghcup         # Installer for the Haskell toolchain (GHC, cabal, HLS)
  go            # The Go programming language
  gofumpt       # Stricter gofmt
  golangci-lint # Runs Go linters
  gradle        # Build tool for Java, Kotlin and Android
  luajit        # Just-In-Time compiler for Lua
  luarocks      # Package manager for Lua modules
  maven         # Build automation tool used primarily for Java projects
  mise          # Tool version manager and task runner (runs these scripts)
  openjdk       # Java Development Kit (latest)
  pipx          # Installs Python apps in isolated environments
  pnpm          # Fast, disk-efficient Node package manager
  poetry        # Python packaging and dependency management
  prettier      # Code formatter for JavaScript, CSS, markdown...
  pyright       # Python type checker and language server
  python@3.13   # Python (uv and mise handle other versions)
  rebar3        # Erlang build tool
  ruff          # Fast Python linter and formatter
  rustup        # Rust toolchain installer
  typescript    # TypeScript compiler (tsc)
  uv            # Fast Python package and project manager
  yarn          # JavaScript package manager

  # Command-line tools
  asciinema         # Record and share terminal sessions
  cargo-binstall    # Installs Rust binaries without building them (the crates below)
  codex             # OpenAI's coding agent CLI
  cowsay            # Configurable talking cow (or other character) in terminal
  docker            # Docker CLI
  exiftool          # Reads and writes image, audio and video metadata
  ffmpeg            # Records, converts and streams audio and video
  figlet            # Large ASCII-art banners from text
  flyctl            # Fly.io command-line tool
  fontforge         # Font editor
  fortune           # Random quotations
  graphviz          # Graph visualization (dot)
  hex               # Colorized hexdump (hx)
  htop              # Interactive process viewer
  imagemagick       # Software suite to create, edit, compose, or convert images
  iperf3            # Measures network bandwidth
  irssi             # IRC client
  mas               # Mac App Store CLI; installs the mas list below
  ncdu              # Disk usage analyzer with a terminal UI
  ollama            # Runs large language models locally
  pandoc            # Universal document converter
  postgresql@17     # PostgreSQL database server
  presenterm        # Slideshows from markdown in the terminal
  probe-rs-tools    # Flash and debug embedded ARM and RISC-V chips
  pwgen             # Password generator
  qrencode          # Makes QR codes
  sevenzip          # 7-Zip archiver (7zz)
  shellcheck        # Static analysis tool for shell scripts
  task              # Taskwarrior, a command-line todo list
  taskwarrior-tui   # Terminal UI for Taskwarrior
  terraform         # Infrastructure as code
  timewarrior       # Command-line time tracking
  tmux-mem-cpu-load # CPU, memory and load for the tmux status line
  tokei             # Counts lines of code
  tree              # Display directories as trees
  typst             # Markup-based typesetting system
  watch             # Runs a command repeatedly, showing its output
  wdiff             # Word-by-word diff
  wget              # Retrieves files over HTTP, HTTPS and FTP
  zola              # Static site generator

  # From other taps
  morantron/tmux-fingers/tmux-fingers # Copy text from tmux panes by hint, like vimium
  pulumi/tap/esc                      # Pulumi ESC: secrets and config management
)

cask=(
  alfred              # Launcher and productivity app
  alt-tab             # Windows-style alt-tab window switcher
  anki                # Spaced-repetition flashcards
  discord             # Voice and text chat
  disk-inventory-x    # Disk usage visualizer
  font-jetbrains-mono # JetBrains Mono font
  ghostty             # Fast, native, GPU-accelerated terminal emulator
  github              # GitHub Desktop
  google-chrome       # Web browser
  google-drive        # Google Drive sync client
  keeweb              # KeePass-compatible password manager
  middleclick         # Middle click with a three-finger tap
  multipass           # Ubuntu VMs on demand
  nextcloud           # Nextcloud desktop sync client
  obsidian            # Markdown notes
  pgadmin4            # PostgreSQL admin UI
  quicklook-json      # Quick Look preview for JSON
  signal              # Encrypted messenger
  spotify             # Music streaming
  steam               # Games
  syntax-highlight    # Quick Look preview for source code, syntax highlighted
  teamspeak-client    # Voice chat
  transmission        # BitTorrent client
)

# Mac App Store apps, by ID (mas; sign in to the App Store first).
mas=(
  1352778147 # Bitwarden: password manager
  682658836  # GarageBand: music creation
  1452453066 # Hidden Bar: hides menu bar icons
  408981434  # iMovie: video editing
  6472865291 # Keymapp: ZSA keyboard layout tool
  409183694  # Keynote: presentations
  302584613  # Kindle: ebooks
  409203825  # Numbers: spreadsheets
  409201541  # Pages: word processor
  545519333  # Prime Video: streaming
  803453959  # Slack: team chat
  899247664  # TestFlight: beta iOS and Mac apps
  310633997  # WhatsApp: messenger
  1295203466 # Windows App: remote desktop to Windows
  1451685025 # WireGuard: VPN
  497799835  # Xcode: Apple's IDE and SDKs
)

# Rust tools, with cargo binstall once rustup is set up.
crates=(
  cargo-expand      # Shows code after macro expansion
  cargo-machete     # Finds unused dependencies
  cargo-outdated    # Lists outdated dependencies
  cargo-usage-rules # Gathers dependencies' usage rules for coding agents
  cargo-watch       # Reruns cargo commands when files change
  create-tauri-app  # Scaffolds Tauri apps
  dioxus-cli        # Dioxus app framework CLI (dx)
  espflash          # Flashes ESP32 chips
  espup             # Installs the Rust toolchains for ESP chips
  evcxr_jupyter     # Rust kernel for Jupyter
  evcxr_repl        # Rust REPL
  flamegraph        # Flame graphs of a program's CPU use (cargo flamegraph)
  flip-link         # Stack overflow protection for embedded Rust
  ldproxy           # Linker proxy for esp-idf Rust builds
  loco              # Loco, a Rails-like Rust web framework
  mdcat             # Renders markdown in the terminal
  sea-orm-cli       # SeaORM migrations and entity generation
  tauri-cli         # Tauri CLI (cargo tauri)
  tokio-console     # Debugger for async Tokio programs
)
