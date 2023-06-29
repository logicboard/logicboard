defmodule Logicboard.Languages.Python3 do
  @behaviour Logicboard.Language
  def name do
    "Python 3"
  end

  def version do
    "3.11"
  end

  def container_image() do
    "python_3:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "python #{main.name}"
  end

  def repl_command(_files) do
    "python -i"
  end

end
