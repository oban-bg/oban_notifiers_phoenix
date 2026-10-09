defmodule Oban.Notifiers.PhoenixTest do
  use ExUnit.Case, async: true

  alias Oban.{Config, Notifier}

  defmodule Repo do
    use Ecto.Repo, otp_app: :oban, adapter: Ecto.Adapters.Postgres
  end

  setup config do
    start_supervised!({Phoenix.PubSub, name: config.test})

    opts = [
      notifier: {Oban.Notifiers.Phoenix, pubsub: config.test},
      peer: Oban.Peers.Isolated,
      stage_interval: :infinity,
      repo: Repo
    ]

    start_supervised!({Oban, opts})

    :ok
  end

  test "broadcasting notifications to subscribers" do
    :ok = Notifier.listen(:signal)
    :ok = Notifier.notify(:signal, %{incoming: "message"})

    assert_receive {:notification, :signal, %{"incoming" => "message"}}
  end

  test "notifying with complex types" do
    Notifier.listen([:insert, :gossip, :signal])

    Notifier.notify(:signal, %{
      date: ~D[2021-08-09],
      keyword: [a: 1, b: 1],
      map: %{tuple: {1, :second}},
      tuple: {1, :second}
    })

    assert_receive {:notification, :signal, notice}
    assert %{"date" => "2021-08-09", "keyword" => [["a", 1], ["b", 1]]} = notice
    assert %{"map" => %{"tuple" => [1, "second"]}, "tuple" => [1, "second"]} = notice
  end

  test "broadcasting on select channels" do
    :ok = Notifier.listen([:signal, :gossip])
    :ok = Notifier.unlisten([:gossip])

    :ok = Notifier.notify(:gossip, %{foo: "bar"})
    :ok = Notifier.notify(:signal, %{baz: "bat"})

    assert_receive {:notification, :signal, _}
    refute_received {:notification, :gossip, _}
  end

  test "broadcasting scoped notifications", config do
    :ok = Notifier.listen(:signal)

    # We can't start two instances with the same name on a single node, so fake it by sending a
    # direct broadcast.
    broadcast = fn payload ->
      Phoenix.PubSub.broadcast(
        config.test,
        "signal",
        {Oban, :signal, [payload]},
        Oban.Notifiers.Phoenix
      )
    end

    real_ident = Config.to_ident(Oban.config())
    fake_ident = "Oban.other-node@localhost"

    broadcast.(~s({"action":"real", "ident": "#{real_ident}"}))
    broadcast.(~s({"action":"fake", "ident": "#{fake_ident}"}))

    assert_receive {:notification, :signal, %{"action" => "real"}}
    refute_receive {:notification, :signal, %{"action" => "fake"}}, 50
  end

  test "ignoring dispatches for an instance that isn't running" do
    :ok = Notifier.listen(:signal)

    assert [] =
             Oban.Notifiers.Phoenix.dispatch(
               [{self(), Oban.Notifiers.Phoenix}],
               :none,
               {MissingOban, :signal, [~s({"action":"ignored"})]}
             )

    refute_received {:notification, :signal, _}
  end

  test "safely handling dispatches from older notifier versions" do
    :ok = Notifier.listen(:signal)

    conf = Oban.config()

    assert [] = Oban.Notifiers.Phoenix.dispatch(%{}, self(), {conf, :signal, %{}})
  end
end
