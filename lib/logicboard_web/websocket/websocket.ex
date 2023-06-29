defmodule Logicboard.Websocket do
  @behaviour Phoenix.Socket.Transport
  alias Logicboard.Websocket.{Message, Reply}
  alias Logicboard.Websocket
  alias Logicboard.ExecutionSupervisor
  alias Phoenix.Socket.{Broadcast}

  require Logger

  defstruct assigns: %{},
            serializer: nil,
            session_id: nil,
            endpoint: nil,
            transport_pid: nil

  defmodule InvalidMessageError do
    @moduledoc """
    Raised when the socket message is invalid.
    """
    defexception [:message]
  end

  def child_spec(_opts) do
    # We won't spawn any process, so let's ignore the child spec
    :ignore
  end

  def connect(%{options: options, params: params, endpoint: endpoint}) do
    vsn = params["vsn"] || "1.0.0"
    sessionId = params["session_id"] || Nanoid.generate()
    case negotiate_serializer(Keyword.fetch!(options, :serializer), vsn) do
      {:ok, serializer} ->
        {:ok, %Websocket{serializer: serializer, session_id: sessionId, endpoint: endpoint}}
      :error ->
        :error
    end
  end

  def id(%Websocket{session_id: sessionId}) do
    sessionId
  end

  def init(%Websocket{session_id: sessionId, endpoint: endpoint} = state) do
    sessionId && endpoint.subscribe(sessionId, link: true)
    {:ok, assign(state, transport_pid: self())}
  end

  def handle_in({payload, opts}, %{serializer: serializer} = state) do
    message = serializer.decode!(payload, opts)
    handle_message(message, state)
  end

  def handle_info(%Broadcast{} = broadcast, state) do
    reply(%Reply{event: broadcast.event, payload: broadcast.payload}, state)
  end

  def handle_info(info, state) do
    Logger.warn("SOCKET TODO handle_info: #{inspect(info)}")
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp handle_message(%Message{} = message, state) do
    ExecutionSupervisor.route_message(state.session_id, message)
    {:ok, state}
  end

  defp handle_message(:unknown_message, state) do
    reply(%Reply{event: :error, payload: %{message: "Invalid message"}}, state)
  end

  defp reply(%Reply{} = reply, %{serializer: serializer} = state) do
    {:socket_push, opcode, payload} = serializer.encode!(reply)
    {:reply, :error, {opcode, payload}, state}
  end

  defp negotiate_serializer(serializers, vsn) when is_list(serializers) do
    case Version.parse(vsn) do
      {:ok, vsn} ->
        serializers
        |> Enum.find(:error, fn {_serializer, vsn_req} -> Version.match?(vsn, vsn_req) end)
        |> case do
          {serializer, _vsn_req} ->
            {:ok, serializer}

          :error ->
            Logger.error "The client's requested transport version \"#{vsn}\" " <>
                          "does not match server's version requirements of #{inspect serializers}"
            :error
        end
      :error ->
        Logger.error "Client sent invalid transport version \"#{vsn}\""
        :error
    end
  end

  def assign(%Websocket{} = socket, key, value) do
    assign(socket, [{key, value}])
  end

  def assign(%Websocket{} = socket, attrs)
  when is_map(attrs) or is_list(attrs) do
    %{socket | assigns: Map.merge(socket.assigns, Map.new(attrs))}
  end

end
