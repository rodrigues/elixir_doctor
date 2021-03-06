defmodule ElixirDoctor.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_doctor,
      description: "Lightweight tracing and debugging on top of erlang_doctor",
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: [
        {:erlang_doctor, "~> 0.1"},
        {:ex_doc, "~> 0.24.1", only: :dev, runtime: false}
      ],
      package: [
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => "https://github.com/rodrigues/elixir_doctor"}
      ]
    ]
  end
end
