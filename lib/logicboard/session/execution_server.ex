defmodule Logicboard.ExecutionServer do
  use GenServer
  use Timex
  alias Logicboard.Websocket.{Message, Broadcast}
  alias Logicboard.ExecutionState

  require Logger

  @timeout 1000*60*1

  def child_spec(arg) do
    %{id: __MODULE__, restart: :temporary, start: {__MODULE__, :start_link, [arg]}}
  end

  def start_link({sessionId, message}) do
    state = ExecutionState.new(sessionId, message)
    GenServer.start_link(__MODULE__, [state], name: {:global, sessionId})
  end

  def init([state]) do
    GenServer.cast(self(), :start)
    {:ok, state,  @timeout}
  end

  def handle_info({:stdout, _, output}, state) do
    LogicboardWeb.Endpoint.broadcast(state.session_id, "stdout", %{content: output})
    {:noreply, state,  @timeout}
  end

  def handle_info({:stderr, _, output}, state) do
    LogicboardWeb.Endpoint.broadcast(state.session_id, "stderr", %{content: output})
    {:noreply, state,  @timeout}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, %ExecutionState{state | terminate_reason: :timeout}}
  end

  def handle_info({:EXIT, pid, status}, state) do
    {:stop, :normal, %ExecutionState{state | terminate_reason: :exit}}
  end

  def handle_cast(%Message{event: "stdin", payload: payload}, state) do
    Exexec.send(state.os_pid, "#{payload.content}\n")
    {:noreply, state,  @timeout}
  end

  def handle_cast(%Message{event: "kill"}, state) do
    {:stop, :normal, %ExecutionState{state | terminate_reason: :kill}}
  end

  def handle_cast(:start, state) do
    containerName = Base.url_encode64("#{state.session_id}:#{Nanoid.generate()}", padding: false)
    containerImage = state.module.container_image()
    localDir = Logicboard.FileHelper.clone(state.files)
    dockerDir = Path.join("/home", "app")
    execCommand = if state.type == "run", do: state.module.run_command(state.files), else: state.module.repl_command(state.files)
    dockerCommand = "docker run --name #{containerName} --cap-drop all --rm -v #{localDir}:#{dockerDir} -it #{containerImage} /bin/bash -c \"#{execCommand}\""
    {:ok, execPID, osPID} = Exexec.run_link(dockerCommand, [
                                      {:stdout, self()},
                                      {:stderr, :stdout},
                                      {:stdin, true},
                                      {:pty, true},
                                      {:monitor, true},
                                      {:kill_group, true},
                                      {:kill_timeout, 1}])
    nextState = %ExecutionState{state | local_dir: localDir, exec_pid: execPID, os_pid: osPID, container: containerName, timestamp: Duration.now}
    # trap_exit will invoke terminate function and gracefully terminate if the process receives :EXIT
    Process.flag(:trap_exit, true)
    {:noreply, nextState,  @timeout}
  end

  def terminate(reason, state) do
    # Kill exec process (which will also kill the container)
    %ExecutionState{os_pid: osPID, container: container} = state
    if is_pid(osPID), do: Exexec.kill(osPID, 9), else: :ignore
    payload = %{reason: state.terminate_reason || reason}
    case state.type do
      "run" ->
        LogicboardWeb.Endpoint.broadcast(state.session_id, "stop", %{reason: state.terminate_reason || reason, message: "Took #{Duration.diff(Duration.now, state.timestamp, :milliseconds)/1000} sec"})
      _ ->
        LogicboardWeb.Endpoint.broadcast(state.session_id, "stop", %{reason: state.terminate_reason || reason, message: "Program Stopped"})
    end
  end

end
