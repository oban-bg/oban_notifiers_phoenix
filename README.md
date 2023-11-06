# Oban.Notifiers.Phoenix

> An [Oban.Notifier][no] that uses [Phoenix.PubSub][pp] for notifications.

[no]: https://hexdocs.pm/oban/Oban.Notifier.html
[pp]: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html

## Usage

Include `:oban_notifiers_phoenix` in your Phoenix application's deps:

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

## Contributing

Run `mix test.ci` locally to ensure changes will pass in CI. That alias executes the following
commands:

* Check formatting (`mix format --check-formatted`)
* Check unused deps (`mix deps.unlock --check-unused`)
* Lint with Credo (`mix credo --strict`)
* Run all tests (`mix test --raise`)
