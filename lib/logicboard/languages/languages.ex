defmodule Logicboard.Language do
  alias Logicboard.Languages.{Python2, Python3, Ruby, Rust, XElixir, JavaScript, TypeScript, PHP, Swift, Bash}

  @callback name() :: {name :: String.t()}
  @callback version() :: {version :: String.t()}
  @callback container_image() :: {container :: String.t()}
  @callback run_command(files :: []) :: String.t()
  @callback repl_command(files :: []) :: String.t()

  @modules %{
  "python_2" => Python2,
  "python_3" => Python3,
  "ruby" => Ruby,
  "rust" => Rust,
  "elixir" => XElixir,
  "javascript" => JavaScript,
  "typescript" => TypeScript,
  "php" => PHP,
  "swift" => Swift,
  "bash" => Bash
  }

  def module(lang) do
    @modules[lang]
  end

end
