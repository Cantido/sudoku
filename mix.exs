defmodule Sudoxu.MixProject do
  use Mix.Project

  def project do
    [
      app: :sudoxu,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:doctor, "~> 0.18.0", only: :dev},
      {:ex_check, "~> 0.14.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:stream_data, "~> 0.5", only: [:dev, :test]}
    ]
  end
end
