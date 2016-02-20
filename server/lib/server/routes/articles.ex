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
      |> put_resp_header("Location","/news/" <> new_article.id)
      |> send_resp(201,"")
  end

end