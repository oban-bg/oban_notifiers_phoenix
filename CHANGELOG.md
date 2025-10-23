# Changelog for Oban Notifier Phoenix

## v0.2.2 — 2025-10-23

- Correct node scoping during dispatch

  The name/node from the config that originally published the message was re-used during local
  dispatch, which prevented the notifier's relay from properly scoping messages. In other words,
  it looked like every message originated locally because the `ident` always matched the current
  node.

  This eliminates the problem by grabbing the config for the local instance by name, rather than
  sharing the node/name and building a static config from it.

## v0.2.1 — 2025-06-24

- Safely handle dispatches from older notifiers

  In order to have graceful upgrades, this restores a clause to handle the older `conf` based
  message format.

## v0.2.0 — 2025-06-04

### Enhancements

- Change notifier to pass config name instead of full config.

  Serializing the config for every notification is needlessly wasteful. Instead pass the config
  name and reconstruct the config in the dispatch function.

- Fetch notifier state directly from the registry.

  State can be fetched from the Oban.Registry rather than with a GenServer call. Even if the call
  is fast, concurrent `notify` calls would be serialized behind GenServer state fetching.

- Minimize data passing with hollow config.

  The notifier's `relay` function only needs the `name` and `node` values from the conf. The
  notifier drops all other fields and manually reconstructs a minimal config rather than pulling
  any data from the registry at runtime.

## v0.1.0 — 2024-02-02

Initial release with full functionality!
