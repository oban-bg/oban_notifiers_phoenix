defmodule ObanNotifiersPhoenix.MixProject do
  use Mix.Project

  @source_url "https://github.com/sorentwo/oban_notifiers_phoenix"
  @version "0.2.1"

  def project do
    [
      app: :oban_notifiers_phoenix,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      preferred_cli_env: ["test.ci": :test],

      # Hex
      name: "Oban Notifiers Phoenix",
      package: package(),
      description: "An Oban Notifier built on Phoenix.PubSub"
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp package do
    [
      maintainers: ["Parker Selbert"],
      licenses: ["Apache-2.0"],
      files: ~w(lib .formatter.exs mix.exs README* CHANGELOG* LICENSE*),
      links: %{
        Changelog: "#{@source_url}/blob/main/CHANGELOG.md",
        GitHub: @source_url
      }
    ]
  end

  defp docs do
    [
      main: "Oban.Notifiers.Phoenix",
      api_reference: false,
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"],
      extras: ["CHANGELOG.md": [title: "Changelog"]],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp deps do
    [
      {:oban, "~> 2.16"},
      {:phoenix_pubsub, "~> 2.0"},
      {:credo, "~> 1.7", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.30", only: [:test, :dev], runtime: false}
    ]
  end

  defp aliases do
    [
      release: [
        "cmd git tag v#{@version}",
        "cmd git push",
        "cmd git push --tags",
        "hex.publish --yes"
      ],
      "test.ci": [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo --strict",
        "test --raise"
      ]
    ]
  end
end
