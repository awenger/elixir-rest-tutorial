# The first REST resource

### First REST Resource with mock routes [6bf4a1e](https://github.com/awenger/elixir-rest-tutorial/commit/6bf4a1e9161c77160206a62d30a9394309c2aa8b)

Before we start to add our first REST resource we should take a look at our dependencies. During the last part we were using old versions of plug and poison. We can update the dependencies in the `mix.exs` file:

```elixir
    [{:cowboy, "~> 1.0.4"},
     {:plug, "~> 1.1.1"},
     {:poison, "~> 2.1.0"}]
```
afterwards we need to update the dependencies with mix: `mix deps.update --all`.

Now that all the libs are up-to-date we can move on to create our first resource for our REST web service.
The first thing to do is define a new struct that we will use to keep the article resources:

```elixir
defmodule Data.Article do
  defstruct [:id ,:href ,:title]

  def from_json_map map do
    %Data.Article{id: map["id"], href: map["href"], title: map["title"]}
  end
end
```
I will explain the purpose of the `from_json_map/1` function later during this part of the tutorial.

Now we need to define the different routes for the article resources. We could add them to the `Server.Routes` module, however I plan to separate the routes for the different resources into different modules. We can foreward all calls with a matching prefix using the `forward` macro to a different Plug:

```elixir
forward "/articles", to: Server.Routes.Articles
```

This forwards calls like `GET /articles/123` to the `Server.Routes.Articles` Plug. In this Plug we can handle the different routes that are applicable for articles:

- `GET /articles/` to retrieve a list of all articles
- `GET /articles/:aid` to retrieve a article with the specified id
- `POST /articles/` to creates a new article

Note that the `/articles/` part is removed by the `foreward` macro, so we only need to match for `"/"` instead of `"/articles/"`.

```elixir
defmodule Server.Routes.Articles do
  use Plug.Router

  plug Plug.Logger, log: :debug
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  get "/" do
    data = [
      %Data.Article{id: 1, href: "http://example.com/article1", title: "Funny Article"},
      %Data.Article{id: 2, href: "http://example.com/article2", title: "Important Article"}
    ]

    conn
      |> put_resp_header("Content-Type","application/json")
      |> send_resp(200, Poison.encode!(data))
  end

  get "/:aid" do
    data = %Data.Article{id: 1, href: "http://example.com/article1", title: "Funny Article"}

    conn
      |> put_resp_header("Content-Type","application/json")
      |> send_resp(200, Poison.encode!(data))
  end

  post "/" do
    new_article = Data.Article.from_json_map(conn.params)
    new_article = %Data.Article{new_article| id: "123"}

    IO.puts "got:"
    IO.inspect new_article

    conn
      |> put_resp_header("Location","/articles/" <> new_article.id)
      |> send_resp(201,"")
  end

end
```

To access the body that is passed by the client to the `POST` route we are utilizing the `Plug.Parsers` Plug. For now we are only interrested in JSON encoded bodies. The parsed JSON body is accesible under `conn.params` as a Elixir map. To transform this map into our `Data.Article` struct we can use the method `from_json_map/1` we created earlier.


### In memory storage of the article resources [50051cd](https://github.com/awenger/elixir-rest-tutorial/commit/50051cd0067a3ef492da8f1d48a8756af5841a0d)

To store the resources of the REST web service in memory we are going to implement a [GenServer](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html). This server stores all the available article resources in a list.

```elixir
defmodule Storage.Articles do
  use GenServer

  # Interface

  def start_link do
    articles = [
      %Data.Article{id: "1", href: "http://example.com/article1", title: "Funny Article"},
      %Data.Article{id: "2", href: "http://example.com/article2", title: "Important Article"}
    ]
    GenServer.start_link(__MODULE__, articles, [name: __MODULE__])
  end

  def list do
    GenServer.call(__MODULE__,{:list})
  end

  def find id do
    GenServer.call(__MODULE__, {:find, id})
  end

  def create %Data.Article{} = article do
    GenServer.call(__MODULE__, {:create, article})
  end

  # Server

  def init articles do
    {:ok, articles}
  end

  def handle_call({:list}, _from, articles) do
    {:reply, articles, articles}
  end

  def handle_call({:find, id}, _from, articles) do
    article = find(articles, id)
    {:reply, article, articles}
  end

  def handle_call({:create, article}, _from, articles) do
    article = %Data.Article{article| id: create_new_id(articles)}
    {:reply, article, [article| articles]}
  end


  defp find(articles, id) do
    articles |> Enum.find(fn(article) -> article.id == id end)
  end

  defp create_new_id(articles) do
    id = create_random_id()
    
    case find(articles, id) do
      nil -> id
      _ -> create_new_id(articles)
    end
  end

  defp create_random_id do
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    alphabet_length = String.length(alphabet)
    0..31 |> Enum.map_join(fn(_) -> 
      String.at(alphabet, :random.uniform(alphabet_length) - 1)
    end)
  end
end
``` 
The `GenServer` is separated into a [interface](https://github.com/awenger/elixir-rest-tutorial/blob/50051cd0067a3ef492da8f1d48a8756af5841a0d/server/lib/storage/articles.ex#L4-L24) (or client) and a [server](https://github.com/awenger/elixir-rest-tutorial/blob/50051cd0067a3ef492da8f1d48a8756af5841a0d/server/lib/storage/articles.ex#L26-L66) area. Other parts of the application should use the interface to talk to the `GenServer`. The server part is responsible to handle the different requests that are made through the interface.

The new `Storage.Articles` `GenServer` is supervised by our `Server` module. This ensures that it is restarted in the case it crashes.

```elixir
    children = [
      # Define workers and child supervisors to be supervised
      # worker(Server.Worker, [arg1, arg2, arg3]),
      Plug.Adapters.Cowboy.child_spec(:http, Server.Routes, [], port: 8080),
      worker(Storage.Articles, [])
    ]
```

Finally we need to adapt the different routes, we created earlier, to utilize this new `GenServer` to retrieve and create article resources. This is how the `Server.Routes.Articles` module looks after these changes:
```elixir
defmodule Server.Routes.Articles do
  use Plug.Router

  plug Plug.Logger, log: :debug
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  get "/" do
    data = Storage.Articles.list()
    conn
      |> set_json_resp
      |> send_resp(200, Poison.encode!(data))
  end

  get "/:aid" do
    data = Storage.Articles.find(aid)

    case data do
      nil -> conn |> set_json_resp |> send_resp(404, Poison.encode!(%{message: "not found"}))
      data -> conn |> set_json_resp |> send_resp(200, Poison.encode!(data))
    end
  end

  post "/" do
    new_article = Data.Article.from_json_map(conn.params)

    new_article = Storage.Articles.create(new_article)

    conn
      |> put_resp_header("Location","/articles/" <> new_article.id)
      |> send_resp(201,"")
  end

  defp set_json_resp(conn), do: conn |> put_resp_header("Content-Type","application/json")

end
```

If we start the web service with `iex -S mix` we can now access the list and the separate articles at [http://localhost:8080/articles](http://localhost:8080/articles) and [http://localhost:8080/articles/1](http://localhost:8080/articles/1).
Furthermore we can create new resources that are then accessible through this routes.

This is how you can create a new article in our web service with `curl`:
```
$ curl -v -XPOST -d "{\"href\":\"http://bla.com/1\",\"title\":\"bla\"}" -H "content-type: application/json" "http://localhost:8080/articles"

* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> POST /articles HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost:8080
> Accept: */*
> content-type: application/json
> Content-Length: 41
> 
* upload completely sent off: 41 out of 41 bytes
< HTTP/1.1 201 Created
* Server Cowboy is not blacklisted
< server: Cowboy
< date: Sat, 20 Feb 2016 19:10:53 GMT
< content-length: 0
< cache-control: max-age=0, private, must-revalidate
< Location: /articles/ZupYbbcd9ILyP23XKsSyXeyLPNeqLa6Y
< 
* Connection #0 to host localhost left intact
```