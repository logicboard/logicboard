defmodule Logicboard.Websocket.Serializer do
  @moduledoc false
  @behaviour Phoenix.Socket.Serializer
  require Logger
  alias Logicboard.Websocket.{Message, Reply}
  alias Phoenix.Socket.{Broadcast}

  def fastlane!(%Broadcast{} = msg) do
    with {:ok, encoded} <- Phoenix.json_library().encode(%{event: msg.event, payload: msg.payload}) do
      {:socket_push, :text, encoded}
    end
  end

  def encode!(%Message{} = msg) do
    with {:ok, encoded} <- Phoenix.json_library().encode(%{event: msg.event, payload: msg.payload}) do
      {:socket_push, :text, encoded}
    end
  end

  def encode!(%Reply{} = reply) do
    with {:ok, encoded} <- Phoenix.json_library().encode(%{event: reply.event, payload: reply.payload}) do
      {:socket_push, :text, encoded}
    end
  end

  def decode!(message, _opts) do
    parsed =
    Phoenix.json_library().decode!(message)
    |> Logicboard.MapUtils.atomize_keys()
    case parsed do
      %{event: event, payload: payload} ->
        %Message{
          event: event,
          payload: payload
        }
      _ ->
        :unknown_message
    end
  end

end
