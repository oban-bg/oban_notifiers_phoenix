defmodule Oban.Notifiers.Phoenix do
  @moduledoc """
  """

  @behaviour Oban.Notifier

  use GenServer

  alias Oban.Notifier
  alias Phoenix.PubSub

  defstruct [:conf, :pubsub, listeners: %{}]

  @impl Notifier
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl Notifier
  def listen(server, channels) do
    with {:ok, %{pubsub: pubsub}} <- GenServer.call(server, :get_state) do
      for channel <- channels, do: PubSub.subscribe(pubsub, to_string(channel))

      :ok
    end
  end

  @impl Notifier
  def unlisten(server, channels) do
    with {:ok, %{pubsub: pubsub}} <- GenServer.call(server, :get_state) do
      for channel <- channels, do: PubSub.unsubscribe(pubsub, to_string(channel))

      :ok
    end
  end

  @impl Notifier
  def notify(server, channel, payload) do
    with {:ok, %{conf: conf, pubsub: pubsub}} <- GenServer.call(server, :get_state) do
      PubSub.broadcast(pubsub, to_string(channel), {conf, channel, payload}, __MODULE__)

      :ok
    end
  end

  @impl GenServer
  def init(opts) do
    {:ok, struct!(__MODULE__, opts)}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @doc false
  def dispatch(entries, _from, {conf, channel, payload}) do
    pids = Enum.map(entries, &elem(&1, 0))

    for message <- payload, do: Notifier.relay(conf, pids, channel, message)
  end
end
