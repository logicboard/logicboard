defmodule Logicboard.Languages.Swift do
  @behaviour Logicboard.Language
  require Logger

  def name do
    "Swift"
  end

  def version do
    "5.8.1"
  end

  def container_image() do
    "swift:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "swift #{main.name}"
  end

  def repl_command(_files) do
    nil
  end

end
