defmodule Logicboard.Languages.Python2 do
  @behaviour Logicboard.Language
  def name do
    "Python 2"
  end

  def version do
    "2.7.17"
  end

  def container_image() do
    "python_2:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "python #{main.name}"
  end

  def repl_command(_files) do
    "python -i"
  end

end
