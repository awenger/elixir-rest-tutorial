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