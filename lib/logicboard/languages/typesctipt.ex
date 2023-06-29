defmodule Logicboard.Languages.TypeScript do
  @behaviour Logicboard.Language
  def name do
    "TypeScript"
  end

  def version do
    "5.1.5"
  end

  def container_image() do
    "typescript:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "ts-node ./#{main.name}"
  end

  def repl_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "ts-node -r ./#{main.name}"
  end

end
