`:dbg` intro

[@fabiankrol](https://github.com/fabiankrol/)

====

`Kernel.dbg != :dbg`

```elixir [1-3|4|6-9|11]
iex(1)> [:a, :b]
        |> Enum.map(&({&1, 42}))
        |> Enum.into(%{})
        |> dbg()

[iex:1: (file)]
[:a, :b] #=> [:a, :b]
|> Enum.map(&{&1, 42}) #=> [a: 42, b: 42]
|> Enum.into(%{}) #=> %{a: 42, b: 42}

%{a: 42, b: 42}
```

[hexdocs.pm](https://hexdocs.pm/elixir/main/Kernel.html#dbg/2)

====

Naive debugging on production

- `IO.inspect/dbg` everything
- hot load on remote shell

====

Can we do better?

## ✨ YES. ✨

====

#### `:dbg`

> The Text Based Trace Facility

> This module implements a text based interface to the `trace/3` and the `trace_pattern/2` BIFs.
> It makes it possible to trace functions, processes, ports and messages.

[erlang docs](https://www.erlang.org/doc/man/dbg)

====

```diff
diff --git a/mix.exs b/mix.exs
@@ -14,7 +14,7 @@ defmodule DbgIntro.MixProject do
   def application do
     [
-      extra_applications: [:logger]
+      extra_applications: [:logger, :runtime_tools]
     ]
   end
```

====

```elixir [1-2|3-4|10-11|6-8]
iex> :dbg.start()
{:ok, #PID<0.143.0>}
iex> :dbg.tracer()
{:ok, #PID<0.143.0>}

# 🔥
# :dbg.p(Item, Flags)
# :dbg.tp*({Module, Function, Arity}, MatchSpec)

iex> :dbg.stop()
:ok
```

====

`:dbg.p(Item, Flags)`

```text [1]
Item := pid()
     | port()
     | :all | :processes | :ports
     | :new | :new_processes | :new_ports
     | :existing | :existing_processes | :existing_ports
     | ...
```
``` text [2,6|2,5]
Flags := Flag | [Flag]
Flag :=
     | :s (send)
     | :r (receive)
     | :m (messages)
     | :c (calls)
     | :p (procs)
     | ...
```


====

`:dbg.tp*(MFA, MatchSpec)`

`trace pattern *tp,tpl,tpe`


```text [1,2]
MFA := {Module, Function, Arity}
    | {:_, :_, :_}
    | ...
```

```text [1-4]
MatchSpec := []
          | :c (caller_trace)
          | :x (exception_trace)
          | :cx (caller_exception_trace)
          | match_spec()
```

====

#### `calls`

====

```elixir
defmodule Intro do
  def init(), do: init([:a, :b])
  def init(list), do: {:ok, init(list, nil)}

  defp init(list, default), do:
    list |> Enum.map(&{&1, default}) |> Map.new()
end
```

```elixir
iex> Intro.init()
{:ok, %{a: nil, b: nil}}
```

====
```elixir
iex> :dbg.p(self(), :c)
{:ok, [{:matched, :nonode@nohost, 1}]}
```

```elixir [0|1|2|4|7|8|10-12]
iex> :dbg.tp({Intro, :init, :_}, [])
{:ok, [{:matched, :nonode@nohost, 2}]}
iex> Intro.init()
(<0.151.0>) call 'Elixir.Intro':init()
{:ok, %{a: nil, b: nil}}
...
iex> :dbg.tpl({Intro, :init, :_}, [])
{:ok, [{:matched, :nonode@nohost, 3}]}
iex)> Intro.init()
(<0.151.0>) call 'Elixir.Intro':init()
(<0.151.0>) call 'Elixir.Intro':init([a,b])
(<0.151.0>) call 'Elixir.Intro':init([a,b],nil)
{:ok, %{a: nil, b: nil}}
```

====
`:c` - caller trace

`:x` - exception trace

`:cx` - caller exception trace

====

```elixir [1|4-9|8-9|1]
iex> :dbg.tpl({Intro, :init, :_}, :c) # caller trace
{:ok, [{:matched, :nonode@nohost, 3}, {:saved, :c}]}
iex> Intro.init()
(<0.139.0>) call 'Elixir.Intro':init()
  ({elixir, '-eval_external_handler/1-fun-2-',4,{"",376}})
(<0.139.0>) call 'Elixir.Intro':init([a,b])
  ({elixir, '-eval_external_handler/1-fun-2-',4,{"",376}})
(<0.139.0>) call 'Elixir.Intro':init([a,b],nil)
  ({'Elixir.Intro',init,1,{"lib/dbg_intro.ex",3}})
```
```elixir [1|4-6|7-12]
iex> :dbg.tpl({Intro, :init, :_}, :x) # exception trace
{:ok, [{:matched, :nonode@nohost, 3}, {:saved, :x}]}
iex> Intro.init()
(<0.139.0>) call 'Elixir.Intro':init()
(<0.139.0>) call 'Elixir.Intro':init([a,b])
(<0.139.0>) call 'Elixir.Intro':init([a,b],nil)
(<0.139.0>) returned from 'Elixir.Intro':init/2
            -> #{a => nil,b => nil}
(<0.139.0>) returned from 'Elixir.Intro':init/1
            -> {ok,#{a => nil,b => nil}}
(<0.139.0>) returned from 'Elixir.Intro':init/0
            -> {ok,#{a => nil,b => nil}}
```

====

#### `messages`

====

```elixir
defmodule Intro do
  def echo(), do: spawn(&loop/0)

  def loop() do
    receive do
      {from, msg} ->
        send(from, msg)
        loop()
    end
  end
end
```

====

```elixir [1-2|3-4|5-6|7,9|10,12,13]
iex> self()
#PID<0.139.0>
iex> echo = Intro.echo()
#PID<0.142.0>
iex(4)> :dbg.p(echo, :m)
{:ok, [{:matched, :nonode@nohost, 1}]}
iex(5)> send(echo, :hello)
:hello
(<0.142.0>) << hello
iex(6)> send(echo, {self(), :hello})
{#PID<0.139.0>, :hello}
(<0.142.0>) << {<0.139.0>,hello}
(<0.142.0>) <0.139.0> ! hello
```
