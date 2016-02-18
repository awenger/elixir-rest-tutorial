# Part 1 - Basic Setup
This part is all about providing the baseline for this tutorial. We are going to create a new Elixir project with mix, setup the first dependencies and wire it all together. The final result is a web service saying Hello World in JSON.

### Project Setup 2cc777cb1e0ee875339b8784bf9e431828b171ea
The new Elixir project `server` is created with mix. The parameter `--sup` tells mix to generate an OTP application skeleton including a supervision tree. This will be later used to supervise the different parts of the server.
```
mix new server --sup
```
### Dependencies 22b3653a8822f44ad365725d17bb6c9eb6c71405
The basic web service has several dependencies, that are configured in the `mix.exs` file:
```elixir
  def application do
    [applications: [:logger],
     mod: {Server, [:cowboy, :plug, :poison]}]
  end

  defp deps do
    [{:cowboy, "~> 1.0.4"},
     {:plug, "~> 1.1.0"},
     {:poison, "~> 1.4.0"}]
  end
```
The specified dependencies are installed with `mix deps.get`. To compile the different dependencies and to verify that everything was installed as expected we can start the [Elixir’s interactive shell](http://elixir-lang.org/docs/master/iex/IEx.html) with `iex -S mix`.

About the dependencies:
- [Cowboy](https://hex.pm/packages/cowboy) - as the underlying web server for the web service

 > Small, fast, modular HTTP server written in Erlang.

- [plug](https://hex.pm/packages/plug) - provides helpers and is the baseline to talk with cowboy

 > A specification and conveniences for composable modules between web applications

- [poison](https://hex.pm/packages/poison) - encode/decode JSON from/to Elixir data structures

 > An incredibly fast, pure Elixir JSON library

### Basic Server 089dfef0ca1af3cf71652875f4df88ae5a9e2f8b
Now that all the dependencies are in place we can wire it all together into a simple web service. The first step therefor is to add the plug adapter as a supervised child to our application `server.ex`:
```elixir
    children = [
      # Define workers and child supervisors to be supervised
      # worker(Server.Worker, [arg1, arg2, arg3]),
      Plug.Adapters.Cowboy.child_spec(:http, Server.Routes, [], port: 8080)
    ]
```
Furthermore we need to provide the basic routing module `Server.Routes` to plug (server/routes.ex):
```elixir
defmodule Server.Routes do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    conn
      |> send_resp(200, "Hello World")
  end

  match _ do
    send_resp(conn, 404, "you shall not pass")
  end
end
```
this provides the default [route](http://localhost:8080/) and a [fallback route](http://localhost:8080/other) for our web service. To start the web service with `iex -S mix` we need to fix the structure of the dependencies we added in the last step (mix.exs):
``` elixir
  def application do
    [applications: [:logger, :cowboy, :plug, :poison],
     mod: {Server, []}]
  end
```

### Serve JSON c5db27f08e011e0e471fe805d959627948440bf9
The last step in this part is to use JSON instead of plain text to say Hello World. This message is provided as Elixir map (`%{key: value}`). We utilize poison to encode this message in the JSON format and serve it with the appropriate `Content-Type` header at our default route:
```elixir
  get "/" do
    data = %{message: "Hello World!"}
    conn
      |> put_resp_header("content-type","application/json")
      |> send_resp(200, Poison.encode!(data))
  end
```