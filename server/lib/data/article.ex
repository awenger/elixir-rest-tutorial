defmodule Data.Article do
  defstruct [:id ,:href ,:title]

  def from_json_map map do
    %Data.Article{id: map["id"], href: map["href"], title: map["title"]}
  end
end