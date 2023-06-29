defmodule Logicboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LogicboardWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Logicboard.PubSub},
      # Start the Endpoint (http/https)
      LogicboardWeb.Endpoint,
      %{
        id: Logicboard.ExecutionSupervisor,
        start: {Logicboard.ExecutionSupervisor, :start_link, [[]]}
      },
      # Start a worker by calling: Logicboard.Worker.start_link(arg)
      # {Logicboard.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Logicboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LogicboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
