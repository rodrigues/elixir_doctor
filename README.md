# ElixirDoctor

Thin library to help using [`erlang_doctor`](https://github.com/chrzaszcz/erlang_doctor) from Elixir.

`erlang_doctor` provides lightweight tracing, debugging and profiling,
backed by ETS.

`elixir_doctor` provides a thin layer to ease make the library a bit
more user-friendly from Elixir, but mostly delegates work to `erlang_doctor`.

## Installation

Add `elixir_doctor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_doctor, "~> 0.2.0"}
  ]
end
```

## Trace function calls

See in [`examples/factorial.exs`](https://github.com/rodrigues/elixir_doctor/blob/master/examples/factorial.exs) an example of a slow module.

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
as the record can change over time.

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

### Consume traces as structs

In Elixir, records are shown simply as tuples, that might make them harder
to understand or manipulate. In case you need, you can convert the traces
to structs that are more introspectable and navigable, by using
`TR.pretty/1` function:

```elixir
iex(7)> TR.filter(fn tr(event: :call, mfa: {_, :sleepy_factorial, _}) -> true end) \
...(7)>  |> TR.pretty()
[
  %TR{
    data: [3],
    event: :call,
    index: 5,
    mfa: {Factorial, :sleepy_factorial, 1},
    pid: #PID<0.206.0>,
    ts: 1617540692495046
  },
  %TR{
    data: [2],
    event: :call,
    index: 6,
    mfa: {Factorial, :sleepy_factorial, 1},
    pid: #PID<0.206.0>,
    ts: 1617540692595598
  },
  %TR{
    data: [1],
    event: :call,
    index: 7,
    mfa: {Factorial, :sleepy_factorial, 1},
    pid: #PID<0.206.0>,
    ts: 1617540692696539
  },
  %TR{
    data: [0],
    event: :call,
    index: 8,
    mfa: {Factorial, :sleepy_factorial, 1},
    pid: #PID<0.206.0>,
    ts: 1617540692797458
  }
]
```

### Stop tracing calls

Stop tracing with the following function:

```elixir
iex(8)> TR.stop_tracing_calls()
:ok
```

It's good to stop it as soon as possible to avoid accumulating too many traces in the ETS table.

Usage of `TR` on production systems is risky, but if you have to do it, start and stop the tracer in the same command,
e.g. for one second with:

```
iex(9)> TR.trace_calls([Factorial]); :timer.sleep(1_000); TR.stop_tracing_calls()
:ok
```

### Tracing options

You can pass a list of modules through `TR.trace_calls/1`.

You can provide `{module, function, arity}` tuples in the list as well.

To get a list of all modules from an appllication, use `TR.app_modules/1`.


### Filters, Ranges, and Tracebacks

With `TR.filter/1` you can spot traces with a matching call:

```elixir
iex(10)> TR.filter(fn tr(data: [2]) -> true end)
[
  {:tr, 4, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [2],
   1617611701543483}
]
```

With `TR.filter_ranges/1` you can get all the traces between the matching call and the corresponding return:


```elixir

iex(11)> TR.filter_ranges(fn tr(data: [2]) -> true end)
[
  [
    {:tr, 4, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [2],
     1617611701543483},
    {:tr, 5, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [1],
     1617611701644514},
    {:tr, 6, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [0],
     1617611701745594},
    {:tr, 7, #PID<0.201.0>, :return_from, {DoctorDemo, :sleepy_factorial, 1}, 1,
     1617611701846544},
    {:tr, 8, #PID<0.201.0>, :return_from, {DoctorDemo, :sleepy_factorial, 1}, 1,
     1617611701846548},
    {:tr, 9, #PID<0.201.0>, :return_from, {DoctorDemo, :sleepy_factorial, 1}, 2,
     1617611701846549}
  ]
]
```

To find the traceback (call stack trace) for matching call, you can use `TR.filter_tracebacks/1`:

```elixir
iex(12)> TR.filter_tracebacks(fn tr(data: [2]) -> true end)
[
  [
    {:tr, 1, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [5],
     1617611701240920},
    {:tr, 2, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [4],
     1617611701341551},
    {:tr, 3, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [3],
     1617611701442561},
    {:tr, 4, #PID<0.201.0>, :call, {DoctorDemo, :sleepy_factorial, 1}, [2],
     1617611701543483}
  ]
]
```

### Select

`TR.select()` can be used to return all collected traces.

`TR.select/1` accepts a function that is passed to [`:ets.fun2ms/1`](https://erlang.org/doc/man/ets.html#fun2ms-1).

With `TR.select/1` you can limit the selection to specific items, and select only some fields from the record:

```elixir
iex(13)> TR.select(fn tr(data: [x], ts: ts) when is_integer(x) and x >= 2 -> {x, ts} end)
[{3, 1617614561788930}, {2, 1617614561889523}]
```
