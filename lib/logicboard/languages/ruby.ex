defmodule Logicboard.Languages.Ruby do
  @behaviour Logicboard.Language
  require Logger

  def name do
    "Ruby"
  end

  def version do
    "3.2.2"
  end

  def container_image() do
    "ruby:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "ruby #{main.name}"
  end

  def repl_command(_files) do
    "irb"
  end

end
