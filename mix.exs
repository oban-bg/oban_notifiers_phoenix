defmodule ObanNotifiersPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :oban_notifiers_phoenix,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:oban, "~> 2.16", github: "sorentwo/oban"},
      {:phoenix_pubsub, "~> 2.0"}
    ]
  end
end
