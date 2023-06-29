defmodule Logicboard.Languages.Bash do
  @behaviour Logicboard.Language
  require Logger

  def name do
    "Bash"
  end

  def version do
    "5.1"
  end

  def container_image() do
    "bash:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "bash #{main.name}"
  end

  def repl_command(_files) do
    "bash -i"
  end

end
