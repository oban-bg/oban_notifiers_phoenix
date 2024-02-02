# Oban.Notifiers.Phoenix

<!-- MDOC -->

An [Oban.Notifier][no] that uses [Phoenix.PubSub][pp] for notifications.

The `Phoenix` notifier allows Oban to share a Phoenix application's `PubSub` for notifications. In
addition to centralizing PubSub communications, it opens up the possible transports to all PubSub
adapters.

Most importantly, as Oban already provides `Postgres` and `PG` notifiers, this package enables
Redis notifications via the [Phoenix.PubSub.Redis][pr] adapter.

[no]: https://hexdocs.pm/oban/Oban.Notifier.html
[pp]: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html
[pr]: https://hex.pm/packages/phoenix_pubsub_redis

## Usage

This package requires a minimum of Oban v2.17 for a few enhancements:

```elixir
defp deps do
  [
    {:oban_notifiers_phoenix, "~> 0.1"},
    ...
  ]
end
```

Make note of your application's `Phoenix.PubSub` instance name from the primary supervision tree:

```elixir
def start(_type, _args) do
  children = [
    {Phoenix.PubSub, name: MyApp.PubSub},
    ...
```

Finally, configure Oban to use `Oban.Notifiers.Phoenix` as the notifier with the `PubSub`
intance name as the `:pubusb` option:

```elixir
config :my_app, Oban,
  notifier: {Oban.Notifiers.Phoenix, pubsub: MyApp.PubSub},
...
```

<!-- MDOC -->

## Contributing

Run `mix test.ci` locally to ensure changes will pass in CI. That alias executes the following
commands:

* Check formatting (`mix format --check-formatted`)
* Check unused deps (`mix deps.unlock --check-unused`)
* Lint with Credo (`mix credo --strict`)
* Run all tests (`mix test --raise`)
