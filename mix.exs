defmodule Temp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :temp,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Temp.Application, []},
    ]
  end

  defp deps do
    [
      # TEST
      {:analyze, "~> 0.0", only: [:dev, :test], runtime: false, override: true},
      {:meck, "~> 0.8", only: :test},
    ]
  end
end
