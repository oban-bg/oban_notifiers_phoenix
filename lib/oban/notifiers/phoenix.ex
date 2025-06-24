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

    # Only the `name` and `node` fields are necessary for scoping in the `relay` function.
    # Constructing a new "hollow" config reduces the total data fetched from the registry on
    # broadcast and dispatch.
    state =
      opts
      |> Keyword.update!(:conf, fn conf -> %Config{name: conf.name, node: conf.node} end)
      |> then(&struct!(__MODULE__, &1))

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl Notifier
  def listen(server, channels) do
    with {:ok, %{pubsub: pubsub}} <- get_state(server) do
      for channel <- channels,
          do: PubSub.subscribe(pubsub, to_string(channel), metadata: __MODULE__)

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
        {conf.name, conf.node, channel, payload},
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
  def dispatch(entries, :none, {name, node, channel, payload}) do
    pids = Enum.map(entries, &elem(&1, 0))
    conf = %Config{name: name, node: node}

    for message <- payload, do: Notifier.relay(conf, pids, channel, message)
  end

  def dispatch(entries, _from, {conf, channel, payload}) do
    dispatch(entries, :none, {conf.name, conf.node, channel, payload})
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
