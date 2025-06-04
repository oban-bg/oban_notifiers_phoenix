# Changelog for Oban Notifier Phoenix

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
