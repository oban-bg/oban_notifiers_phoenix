defmodule Oban.Notifiers.Phoenix do
  @external_resource readme = Path.join([__DIR__, "../../../README.md"])

  @moduledoc readme
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @behaviour Oban.Notifier

  use GenServer

  alias Oban.{Config, Notifier}
  alias Phoenix.PubSub

  defstruct [:conf, :pubsub]

  @doc false
  def child_spec(opts), do: super(opts)

  @impl Notifier
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, struct!(__MODULE__, opts), name: name)
  end

  @impl Notifier
  def listen(server, channels) do
    with {:ok, %{conf: conf, pubsub: pubsub}} <- get_state(server) do
      meta = {conf.name, conf.node}

      for channel <- channels, do: PubSub.subscribe(pubsub, to_string(channel), metadata: meta)

      :ok
    end
  end

  @impl Notifier
  def unlisten(server, channels) do
    with {:ok, %{pubsub: pubsub}} <- get_state(server) do
      for channel <- channels, do: PubSub.unsubscribe(pubsub, to_string(channel))

      :ok
    end
  end

  @impl Notifier
  def notify(server, channel, payload) do
    with {:ok, %{conf: conf, pubsub: pubsub}} <- get_state(server) do
      PubSub.broadcast(
        pubsub,
        to_string(channel),
        {conf.name, channel, payload},
        __MODULE__
      )

      :ok
    end
  end

  @impl GenServer
  def init(state) do
    put_state(state)

    {:ok, state}
  end

  @doc false
  # Backward compatibility with < 0.2.0, which broadcast the full config. This must come first
  # because the shape is otherwise indistinguishable from the current message.
  def dispatch(entries, _from, {%Config{name: name}, channel, payload}) do
    dispatch(entries, :none, {name, channel, payload})
  end

  def dispatch(entries, :none, {name, channel, payload}) do
    for {meta, pids} <- Enum.group_by(entries, &elem(&1, 1), &elem(&1, 0)),
        conf = to_conf(meta, name),
        not is_nil(conf),
        message <- payload,
        do: Notifier.relay(conf, pids, channel, message)
  end

  # Backward compatibility with 0.2.1
  def dispatch(entries, :none, {name, _node, channel, payload}) do
    dispatch(entries, :none, {name, channel, payload})
  end

  defp to_conf({name, node}, _name), do: %Config{name: name, node: node}

  defp to_conf(__MODULE__, name) do
    case Oban.Registry.lookup(name) do
      {_pid, conf} -> conf
      nil -> nil
    end
  end

  defp put_state(state) do
    Registry.update_value(Oban.Registry, {state.conf.name, Oban.Notifier}, fn _ -> state end)
  end

  defp get_state(server) do
    [name] = Registry.keys(Oban.Registry, server)

    case Oban.Registry.lookup(name) do
      {_pid, state} -> {:ok, state}
      nil -> {:error, RuntimeError.exception("no notifier running as #{inspect(name)}")}
    end
  end
end
