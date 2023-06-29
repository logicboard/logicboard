defmodule Logicboard.Languages.XElixir do
  @behaviour Logicboard.Language
  def name do
    "Elixir"
  end

  def version do
    "1.15.0"
  end

  def container_image() do
    "elixir:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "elixir #{main.name}"
  end

  def repl_command(_files) do
    "iex"
  end
end
