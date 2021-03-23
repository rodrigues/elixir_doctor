# ElixirDoctor

Thin library to help using `erlang_doctor` from Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixir_doctor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_doctor, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir

TR.start()
TR.trace_calls([Mod1, Mod2])

Mod1.fun()

TR.stop_tracing_calls()

# returns all entries
TR.select()

# you gotta import TR.tr/1 macro,
# if you want to do pattern matching on records
import TR, only: [tr: 1]

TR.filter(fn tr(event: :call) -> true end)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elixir_doctor](https://hexdocs.pm/elixir_doctor).
