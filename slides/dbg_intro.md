`:dbg` intro

[@fabiankrol](https://github.com/fabiankrol/)

====

```elixir [712: 1-2|3|4]
    "Elixir is cool!"
    |> String.trim_trailing("!")
    |> String.split()
    |> List.first()
    |> dbg()
```
