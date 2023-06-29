defmodule Phoenix.Sockets do

  require Logger
  require Phoenix.Endpoint
  alias Phoenix.Socket
  alias Phoenix.Socket.{Broadcast, Message, Reply}

  @callback connect(params :: map, Socket.t) :: {:ok, Socket.t} | {:error, term} | :error
  @callback connect(params :: map, Socket.t, connect_info :: map) :: {:ok, Socket.t} | {:error, term} | :error


  @callback id(Socket.t) :: String.t | nil

  @optional_callbacks connect: 2, connect: 3

  defmodule InvalidMessageError do
    @moduledoc """
    Raised when the socket message is invalid.
    """
    defexception [:message]
  end

  defstruct assigns: %{},
            channel: nil,
            channel_pid: nil,
            endpoint: nil,
            handler: nil,
            id: nil,
            joined: false,
            join_ref: nil,
            private: %{},
            pubsub_server: nil,
            ref: nil,
            serializer: nil,
            topic: nil,
            transport: nil,
            transport_pid: nil

  @type t :: %Socket{
          assigns: map,
          channel: atom,
          channel_pid: pid,
          endpoint: atom,
          handler: atom,
          id: String.t | nil,
          joined: boolean,
          ref: term,
          private: map,
          pubsub_server: atom,
          serializer: atom,
          topic: String.t,
          transport: atom,
          transport_pid: pid,
        }

  defmacro __using__(opts) do
    quote do
      ## User API

      import Phoenix.Socket
      @behaviour Phoenix.Socket
      @before_compile Phoenix.Socket
      Module.register_attribute(__MODULE__, :phoenix_channels, accumulate: true)
      @phoenix_socket_options unquote(opts)

      ## Callbacks

      @behaviour Phoenix.Socket.Transport

      @doc false
      def child_spec(opts) do
        Phoenix.Socket.__child_spec__(__MODULE__, opts, @phoenix_socket_options)
      end

      @doc false
      def drainer_spec(opts) do
        Phoenix.Socket.__drainer_spec__(__MODULE__, opts, @phoenix_socket_options)
      end

      @doc false
      def connect(map), do: Phoenix.Socket.__connect__(__MODULE__, map, @phoenix_socket_options)

      @doc false
      def init(state), do: Phoenix.Socket.__init__(state)

      @doc false
      def handle_in(message, state), do: Phoenix.Socket.__in__(message, state)

      @doc false
      def handle_info(message, state), do: Phoenix.Socket.__info__(message, state)

      @doc false
      def terminate(reason, state), do: Phoenix.Socket.__terminate__(reason, state)
    end
  end

  ## USER API

  @doc """
  Adds key-value pairs to socket assigns.

  A single key-value pair may be passed, a keyword list or map
  of assigns may be provided to be merged into existing socket
  assigns.

  ## Examples

      iex> assign(socket, :name, "Elixir")
      iex> assign(socket, name: "Elixir", logo: "💧")
  """
  def assign(%Socket{} = socket, key, value) do
    assign(socket, [{key, value}])
  end

  def assign(%Socket{} = socket, attrs)
  when is_map(attrs) or is_list(attrs) do
    %{socket | assigns: Map.merge(socket.assigns, Map.new(attrs))}
  end

  @doc """
  Defines a channel matching the given topic and transports.

    * `topic_pattern` - The string pattern, for example `"room:*"`, `"users:*"`,
      or `"system"`
    * `module` - The channel module handler, for example `MyAppWeb.RoomChannel`
    * `opts` - The optional list of options, see below

  ## Options

    * `:assigns` - the map of socket assigns to merge into the socket on join

  ## Examples

      channel "topic1:*", MyChannel

  ## Topic Patterns

  The `channel` macro accepts topic patterns in two flavors. A splat (the `*`
  character) argument can be provided as the last character to indicate a
  `"topic:subtopic"` match. If a plain string is provided, only that topic will
  match the channel handler. Most use-cases will use the `"topic:*"` pattern to
  allow more versatile topic scoping.

  See `Phoenix.Channel` for more information
  """
  defmacro channel(topic_pattern, module, opts \\ []) do
    module = expand_alias(module, __CALLER__)

    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    quote do
      @phoenix_channels {unquote(topic_pattern), unquote(module), unquote(opts)}
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:channel, 3}})

  defp expand_alias(other, _env), do: other

  @doc false
  @deprecated "transport/3 in Phoenix.Socket is deprecated and has no effect"
  defmacro transport(_name, _module, _config \\ []) do
    :ok
  end

  defmacro __before_compile__(env) do
    channels =
      env.module
      |> Module.get_attribute(:phoenix_channels, [])
      |> Enum.reverse()

    channel_defs =
      for {topic_pattern, module, opts} <- channels do
        topic_pattern
        |> to_topic_match()
        |> defchannel(module, opts)
      end

    quote do
      unquote(channel_defs)
      def __channel__(_topic), do: nil
    end
  end

  defp to_topic_match(topic_pattern) do
    case String.split(topic_pattern, "*") do
      [prefix, ""] -> quote do: <<unquote(prefix) <> _rest>>
      [bare_topic] -> bare_topic
      _            -> raise ArgumentError, "channels using splat patterns must end with *"
    end
  end

  defp defchannel(topic_match, channel_module, opts) do
    quote do
      def __channel__(unquote(topic_match)), do: unquote({channel_module, Macro.escape(opts)})
    end
  end

  ## CALLBACKS IMPLEMENTATION

  def __child_spec__(handler, opts, socket_options) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    opts = Keyword.merge(socket_options, opts)
    partitions = Keyword.get(opts, :partitions, System.schedulers_online())
    args = {endpoint, handler, partitions}
    Supervisor.child_spec({Phoenix.Socket.PoolSupervisor, args}, id: handler)
  end

  def __drainer_spec__(handler, opts, socket_options) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    opts = Keyword.merge(socket_options, opts)

    if drainer = Keyword.get(opts, :drainer, []) do
      {Phoenix.Socket.PoolDrainer, {endpoint, handler, drainer}}
    else
      :ignore
    end
  end

  def __connect__(user_socket, map, socket_options) do
    %{
      endpoint: endpoint,
      options: options,
      transport: transport,
      params: params,
      connect_info: connect_info
    } = map

    vsn = params["vsn"] || "1.0.0"

    options = Keyword.merge(socket_options, options)
    start = System.monotonic_time()

    case negotiate_serializer(Keyword.fetch!(options, :serializer), vsn) do
      {:ok, serializer} ->
        result = user_connect(user_socket, endpoint, transport, serializer, params, connect_info)

        metadata = %{
          endpoint: endpoint,
          transport: transport,
          params: params,
          connect_info: connect_info,
          vsn: vsn,
          user_socket: user_socket,
          log: Keyword.get(options, :log, :info),
          result: result(result),
          serializer: serializer
        }

        duration = System.monotonic_time() - start
        :telemetry.execute([:phoenix, :socket_connected], %{duration: duration}, metadata)
        result

      :error ->
        :error
    end
  end

  defp result({:ok, _}), do: :ok
  defp result(:error), do: :error
  defp result({:error, _}), do: :error

  def __init__({state, %{id: id, endpoint: endpoint} = socket}) do
    _ = id && endpoint.subscribe(id, link: true)
    {:ok, {state, %{socket | transport_pid: self()}}}
  end

  def __in__({payload, opts}, {state, socket}) do
    %{topic: topic} = message = socket.serializer.decode!(payload, opts)
    handle_in(Map.get(state.channels, topic), message, state, socket)
  end

  def __info__({:DOWN, ref, _, pid, reason}, {state, socket}) do
    case state.channels_inverse do
      %{^pid => {topic, join_ref}} ->
        state = delete_channel(state, pid, topic, ref)
        {:push, encode_on_exit(socket, topic, join_ref, reason), {state, socket}}

      %{} ->
        {:ok, {state, socket}}
    end
  end

  def __info__(%Broadcast{event: "disconnect"}, state) do
    {:stop, {:shutdown, :disconnected}, state}
  end

  def __info__(:socket_drain, state) do
    {:stop, {:shutdown, :draining}, state}
  end

  def __info__({:socket_push, opcode, payload}, state) do
    {:push, {opcode, payload}, state}
  end

  def __info__({:socket_close, pid, _reason}, state) do
    socket_close(pid, state)
  end

  def __info__(:garbage_collect, state) do
    :erlang.garbage_collect(self())
    {:ok, state}
  end

  def __info__(_, state) do
    {:ok, state}
  end

  def __terminate__(_reason, _state_socket) do
    :ok
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

  defp user_connect(handler, endpoint, transport, serializer, params, connect_info) do
    # The information in the Phoenix.Socket goes to userland and channels.
    socket = %Socket{
      handler: handler,
      endpoint: endpoint,
      pubsub_server: endpoint.config(:pubsub_server),
      serializer: serializer,
      transport: transport
    }

    # The information in the state is kept only inside the socket process.
    state = %{
      channels: %{},
      channels_inverse: %{}
    }

    connect_result =
      if function_exported?(handler, :connect, 3) do
        handler.connect(params, socket, connect_info)
      else
        handler.connect(params, socket)
      end

    case connect_result do
      {:ok, %Socket{} = socket} ->
        case handler.id(socket) do
          nil ->
            {:ok, {state, socket}}

          id when is_binary(id) ->
            {:ok, {state, %{socket | id: id}}}

          invalid ->
            Logger.error "#{inspect handler}.id/1 returned invalid identifier " <>
                           "#{inspect invalid}. Expected nil or a string."
            :error
        end

      :error ->
        :error

      {:error, _reason} = err ->
        err

      invalid ->
        connect_arity = if function_exported?(handler, :connect, 3), do: "connect/3", else: "connect/2"
        Logger.error "#{inspect handler}. #{connect_arity} returned invalid value #{inspect invalid}. " <>
                     "Expected {:ok, socket}, {:error, reason} or :error"
        :error
    end
  end

  defp handle_in(_, %{ref: ref, topic: "phoenix", event: "heartbeat"}, state, socket) do
    reply = %Reply{
      ref: ref,
      topic: "phoenix",
      status: :ok,
      payload: %{}
    }

    {:reply, :ok, encode_reply(socket, reply), {state, socket}}
  end

  defp handle_in(nil, %{event: "phx_join", topic: topic, ref: ref, join_ref: join_ref} = message, state, socket) do
    case socket.handler.__channel__(topic) do
      {channel, opts} ->
        case Phoenix.Channel.Server.join(socket, channel, message, opts) do
          {:ok, reply, pid} ->
            reply = %Reply{join_ref: join_ref, ref: ref, topic: topic, status: :ok, payload: reply}
            state = put_channel(state, pid, topic, join_ref)
            {:reply, :ok, encode_reply(socket, reply), {state, socket}}

          {:error, reply} ->
            reply = %Reply{join_ref: join_ref, ref: ref, topic: topic, status: :error, payload: reply}
            {:reply, :error, encode_reply(socket, reply), {state, socket}}
        end

      _ ->
        Logger.warning "Ignoring unmatched topic \"#{topic}\" in #{inspect(socket.handler)}"
        {:reply, :error, encode_ignore(socket, message), {state, socket}}
    end
  end

  defp handle_in({pid, _ref, status}, %{event: "phx_join", topic: topic} = message, state, socket) do
    receive do
      {:socket_close, ^pid, _reason} -> :ok
    after
      0 ->
        if status != :leaving do
          Logger.debug(fn ->
            "Duplicate channel join for topic \"#{topic}\" in #{inspect(socket.handler)}. " <>
            "Closing existing channel for new join."
          end)
        end
    end

    :ok = shutdown_duplicate_channel(pid)
    {:push, {opcode, payload}, {new_state, new_socket}} = socket_close(pid, {state, socket})
    send(self(), {:socket_push, opcode, payload})
    handle_in(nil, message, new_state, new_socket)
  end

  defp handle_in({pid, _ref, _status}, %{event: "phx_leave"} = msg, state, socket) do
    %{topic: topic, join_ref: join_ref} = msg

    case state.channels_inverse do
      # we need to match on nil to handle v1 protocol
      %{^pid => {^topic, existing_join_ref}} when existing_join_ref in [join_ref, nil] ->
        send(pid, msg)
        {:ok, {update_channel_status(state, pid, topic, :leaving), socket}}

      # the client has raced a server close. No need to reply since we already sent close
      %{^pid => {^topic, _old_join_ref}} ->
        {:ok, {state, socket}}
    end
  end

  defp handle_in({pid, _ref, _status}, message, state, socket) do
    send(pid, message)
    {:ok, {state, socket}}
  end

  defp handle_in(nil, %{event: "phx_leave", ref: ref, topic: topic, join_ref: join_ref}, state, socket) do
    reply = %Reply{
      ref: ref,
      join_ref: join_ref,
      topic: topic,
      status: :ok,
      payload: %{}
    }

    {:reply, :ok, encode_reply(socket, reply), {state, socket}}
  end

  defp handle_in(nil, message, state, socket) do
    # This clause can happen if the server drops the channel
    # and the client sends a message meanwhile
    {:reply, :error, encode_ignore(socket, message), {state, socket}}
  end

  defp put_channel(state, pid, topic, join_ref) do
    %{channels: channels, channels_inverse: channels_inverse} = state
    monitor_ref = Process.monitor(pid)

    %{
      state |
        channels: Map.put(channels, topic, {pid, monitor_ref, :joined}),
        channels_inverse: Map.put(channels_inverse, pid, {topic, join_ref})
    }
  end

  defp delete_channel(state, pid, topic, monitor_ref) do
    %{channels: channels, channels_inverse: channels_inverse} = state
    Process.demonitor(monitor_ref, [:flush])

    %{
      state |
        channels: Map.delete(channels, topic),
        channels_inverse: Map.delete(channels_inverse, pid)
    }
  end

  defp encode_on_exit(socket, topic, ref, _reason) do
    message = %Message{join_ref: ref, ref: ref, topic: topic, event: "phx_error", payload: %{}}
    encode_reply(socket, message)
  end

  defp encode_ignore(socket, %{ref: ref, topic: topic}) do
    reply = %Reply{ref: ref, topic: topic, status: :error, payload: %{reason: "unmatched topic"}}
    encode_reply(socket, reply)
  end

  defp encode_reply(%{serializer: serializer}, message) do
    {:socket_push, opcode, payload} = serializer.encode!(message)
    {opcode, payload}
  end

  defp encode_close(socket, topic, join_ref) do
    message = %Message{join_ref: join_ref, ref: join_ref, topic: topic, event: "phx_close", payload: %{}}
    encode_reply(socket, message)
  end

  defp shutdown_duplicate_channel(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, {:shutdown, :duplicate_join})

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    after
      5_000 ->
        Process.exit(pid, :kill)
        receive do: ({:DOWN, ^ref, _, _, _} -> :ok)
    end
  end

  defp socket_close(pid, {state, socket}) do
    case state.channels_inverse do
      %{^pid => {topic, join_ref}} ->
        {^pid, monitor_ref, _status} = Map.fetch!(state.channels, topic)
        state = delete_channel(state, pid, topic, monitor_ref)
        {:push, encode_close(socket, topic, join_ref), {state, socket}}

      %{} ->
        {:ok, {state, socket}}
    end
  end

  defp update_channel_status(state, pid, topic, status) do
    new_channels = Map.update!(state.channels, topic, fn {^pid, ref, _} -> {pid, ref, status} end)
    %{state | channels: new_channels}
  end
end
