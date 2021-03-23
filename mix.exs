defmodule ElixirDoctor.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_doctor,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: [{:erlang_doctor, "~> 0.1"}],
      package: [
        licenses: ["Apache-2.0"]
      ]
    ]
  end
end
