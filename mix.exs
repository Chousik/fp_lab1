defmodule Fplab1.MixProject do
  use Mix.Project

  def project do
    [
      app: :fplab1,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Fplab1.CLI]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.6", only: :test}
    ]
  end
end
