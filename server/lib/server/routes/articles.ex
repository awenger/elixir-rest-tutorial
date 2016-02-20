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
      |> put_resp_header("Location","/news/" <> new_article.id)
      |> send_resp(201,"")
  end

  defp set_json_resp(conn), do: conn |> put_resp_header("Content-Type","application/json")

end