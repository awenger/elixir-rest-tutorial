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