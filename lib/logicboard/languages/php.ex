defmodule Logicboard.Languages.PHP do
  @behaviour Logicboard.Language
  require Logger

  def name do
    "PHP"
  end

  def version do
    "8.2.7"
  end

  def container_image() do
    "php:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "php #{main.name}"
  end

  def repl_command(_files) do
    "php -a"
  end

end
