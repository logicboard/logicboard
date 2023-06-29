defmodule Logicboard.FileHelper do
  require Logger

  def clone(files) do
    dir = mk_dir()
    clone(files, dir)
    dir
  end

  def clone(files, dir) do
    Enum.each(files, fn file ->
      fileName = Path.join(dir, file[:name])
      case file[:directory] do
        true ->
          :ok = File.mkdir_p(fileName)
          acc = clone(file[:content], fileName)
          acc
        false ->
          fileName = Path.join(dir, file[:name])
          File.write!(fileName, file[:content])
      end
    end)
  end

  def find_main(files, result \\ nil) do
    Enum.reduce(files, result, fn file, acc ->
      case file[:directory] do
        true ->
          find_main(file[:content], acc)
        false ->
          case {acc, file[:main]} do
            {nil, true} ->
              file
            _ ->
              acc
          end
      end
    end)
  end

  def mk_dir() do
    baseDir =  Application.get_env(:logicboard, :code_directory)
    path = Path.join(baseDir, Nanoid.generate())
    :ok = File.mkdir_p(path)
    path
  end

end
