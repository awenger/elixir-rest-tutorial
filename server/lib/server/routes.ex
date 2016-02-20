defmodule Server.Routes do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    data = %{message: "Hello World!"}
    conn
      |> put_resp_header("content-type","application/json")
      |> send_resp(200, Poison.encode!(data))
  end

  forward "/articles", to: Server.Routes.Articles

  match _ do
    send_resp(conn, 404, "you shall not pass")
  end
end