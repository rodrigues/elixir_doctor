# ElixirDoctor

Thin library to help using [`erlang_doctor`](https://github.com/chrzaszcz/erlang_doctor) from Elixir.

`erlang_doctor` provides lightweight tracing, debugging and profiling,
backed by `ets`.

## Installation

Add `elixir_doctor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_doctor, "~> 0.2.0"}
  ]
end
```

## Tracing function calls

See in `examples/factorial.exs` an example of a slow module.

In the following `iex` session, we compile this module and trace its execution:

```elixir
$ iex -S mix
Erlang/OTP 23 [erts-11.1.8] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [hipe]

Interactive Elixir (1.11.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> c "examples/factorial.exs"
[Factorial]
iex(2)> TR.trace_calls([Factorial])
:ok
iex(3)> Factorial.sleepy_factorial(3)
6
iex(4)> TR.filter(fn _ -> true end)
[
  {:tr, 1, #PID<0.192.0>, :call, {Factorial, :__info__, 1}, [:deprecated],
   1617454844669762},
  {:tr, 2, #PID<0.192.0>, :return_from, {Factorial, :__info__, 1}, [],
   1617454844669769},
  {:tr, 3, #PID<0.192.0>, :call, {Factorial, :__info__, 1}, [:macros],
   1617454844669774},
  {:tr, 4, #PID<0.192.0>, :return_from, {Factorial, :__info__, 1}, [],
   1617454844669776},
  {:tr, 5, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [3],
   1617454844669798},
  {:tr, 6, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [2],
   1617454844770838},
  {:tr, 7, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [1],
   1617454844871993},
  {:tr, 8, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [0],
   1617454844972913},
  {:tr, 9, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 1,
   1617454845073992},
  {:tr, 10, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 1,
   1617454845074000},
  {:tr, 11, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 2,
   1617454845074002},
  {:tr, 12, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 6,
   1617454845074004}
]
```
The `TR.filter/1` call receives a predicate, in this case with `fn _ -> true end`
all traces are returned.

Each tracing entry returned a `:tr` record, a tuple with the following spec:

```elixir
{:tr,
  index :: pos_integer(),
  pid :: pid(),
  event :: :call | :return_from | :exception_from,
  mfa :: {atom(), atom(), non_neg_integer()},
  data :: term(),
  ts :: integer()}
```

The first 4 entries of the list are related to 2 function calls made by iex
itself, exploring module deprecations and macros:

```elixir
[{:tr, 1, #PID<0.192.0>, :call, {Factorial, :__info__, 1}, [:deprecated],
  1617454844669762},
 {:tr, 2, #PID<0.192.0>, :return_from, {Factorial, :__info__, 1}, [],
  1617454844669769},
 {:tr, 3, #PID<0.192.0>, :call, {Factorial, :__info__, 1}, [:macros],
  1617454844669774},
 {:tr, 4, #PID<0.192.0>, :return_from, {Factorial, :__info__, 1}, [],
  1617454844669776} | _ ]
```

To ignore the traces for `Factorial.__info__(:deprecated)` and
`Factorial.__info__(:macros)`, and return only the traces
related to the `sleepy_factorial/1` function call, we should pattern
match on the function name `:sleepy_factorial` in the mfa.

It can be done like this:

```elixir
> TR.filter(fn {:tr, _, _, _, {_, :sleepy_factorial, _}, _, _} -> true end)
```

But that is very error-prone, not very ergonomic or future-proof,
as the record can for instance get a new field over time.

What is recommended is to import the module `TR`, using the `tr` macro
to pattern match on the mfa:

```elixir
iex(5)> import TR
TR
iex(6)> TR.filter(fn tr(mfa: {_, :sleepy_factorial, _}) -> true end)
[
  {:tr, 5, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [3],
   1617458856447276},
  {:tr, 6, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [2],
   1617458856548038},
  {:tr, 7, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [1],
   1617458856649037},
  {:tr, 8, #PID<0.192.0>, :call, {Factorial, :sleepy_factorial, 1}, [0],
   1617458856750092},
  {:tr, 9, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 1,
   1617458856851100},
  {:tr, 10, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 1,
   1617458856851107},
  {:tr, 11, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 2,
   1617458856851109},
  {:tr, 12, #PID<0.192.0>, :return_from, {Factorial, :sleepy_factorial, 1}, 6,
   1617458856851110}
]
```

Now we can see the traces for each recursive `:call` to the function,
with argument `3`, `2`, `1` and `0`, and their respective returns, traced
through the `:return_from` events, with return values `1`, `1`, `2`, and finally `6`.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elixir_doctor](https://hexdocs.pm/elixir_doctor).
