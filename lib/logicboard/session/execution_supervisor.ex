defmodule Logicboard.ExecutionSupervisor do
  use DynamicSupervisor
  alias Logicboard.Websocket.{Message}
  alias Logicboard.ExecutionServer
  require Logger

  def route_message(sessionId, %Message{event: event} = message) when event in ["run",  "repl"] do
    where_is(sessionId) |> kill()
    spec = ExecutionServer.child_spec({sessionId, message})
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def route_message(sessionId, %Message{event: event} = message) when event in ["kill"] do
    where_is(sessionId) |> kill()
  end

  def route_message(sessionId, %Message{event: event} = message) do
    case where_is(sessionId) do
      pid when is_pid(pid) ->
        GenServer.cast({:global, sessionId}, message)
      _ ->
        LogicboardWeb.Endpoint.broadcast(sessionId, "error", %{content: "No active REPL session, enter REPL() to start"})
    end
  end

  defp where_is(sessionId) do
    GenServer.whereis({:global, sessionId})
  end

  defp kill(pid) do
    case pid do
      pid_ when is_pid(pid_) ->
        GenServer.stop(pid_, :kill)
      _ ->
        :ignore
    end
  end

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
