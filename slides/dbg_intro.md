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
