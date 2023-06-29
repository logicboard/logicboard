
defmodule Logicboard.ExecutionState do
  require Logger
  alias Logicboard.ExecutionState
  alias Logicboard.Websocket.{Message}

  defstruct [
    type: nil,
    session_id: nil,
    module: nil,
    local_dir: nil,
    files: [],
    exec_pid: nil,
    os_pid: nil,
    container: nil,
    terminate_reason: nil,
    timestamp: nil,
  ]

  def new(sessionId, %Message{event: event, payload: %{language: language, files: files}}) do
    module = Logicboard.Language.module(language)
    %ExecutionState{type: event, session_id: sessionId, module: module, files: files}
  end

end
