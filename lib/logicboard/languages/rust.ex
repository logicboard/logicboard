defmodule Logicboard.Languages.Rust do
  @behaviour Logicboard.Language
  require Logger

  def name do
    "Rust"
  end

  def version do
    "1.70.0"
  end

  def container_image() do
    "rust:logicboard"
  end

  def run_command(files) do
    main = Logicboard.FileHelper.find_main(files)
    "rustc #{main.name} && ./#{Path.rootname(main.name)}"
  end

  def repl_command(_files) do
    nil
  end

end
