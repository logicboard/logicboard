defmodule Logicboard.MapUtils do

  def atomize_keys(nil), do: nil

  def atomize_keys(struct = %{__struct__: _}) do
    struct
  end

  def atomize_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(not_a_map) do
    not_a_map
  end

end
