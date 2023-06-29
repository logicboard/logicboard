defmodule Logicboard.Websocket.Message do
  defstruct event: nil, payload: nil

  def from_map!(map) when is_map(map) do
    try do
      %Logicboard.Websocket.Message {
        event: Map.fetch!(map, "event"),
        payload: Map.fetch!(map, "payload"),
      }
    rescue
      err in [KeyError] ->
        raise Logicboard.Websocket.InvalidMessageError, "missing key #{inspect(err.key)}"
    end
  end
end

defmodule Logicboard.Websocket.Reply do
  defstruct event: nil, payload: nil

  def from_map!(map) when is_map(map) do
    try do
      %Logicboard.Websocket.Reply {
        event: Map.fetch!(map, "event"),
        payload: Map.fetch!(map, "payload"),
      }
    rescue
      err in [KeyError] ->
        raise Logicboard.Websocket.InvalidMessageError, "missing key #{inspect(err.key)}"
    end
  end
end
