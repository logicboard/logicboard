defmodule Logicboard.Languages.JavaScript do
  @behaviour Logicboard.Language
  def name do
    "JavaScript"
  end

  def version do
    "20.3.1"
  end

  def container_image() do
    "javascript:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "node #{main.name}"
  end

  def repl_command(_files) do
    "node"
  end

end
