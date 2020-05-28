defmodule ZenodoApiStream do
  # Return a lazily evaluated stream of all API response page bodies.
  def response_pages(search_url: search_url) do
    Stream.resource(
      fn -> {search_url} end,
      &get_page/1,
      fn _state -> nil end
    )
  end

  # If the url is nil there are no more pages to get.
  def get_page({_page_url = nil}) do
    {:halt, []}
  end

  # return a page of json at a time, caller should pull records
  def get_page({page_url}) do
    {:ok, %{body: body}} = HTTPoison.get(page_url)

    json =
      body
      |> Poison.decode!()

    next_path =
      json
      |> Map.fetch!("links")
      |> Map.get("next", nil)

    {[json], {next_path}}
  end
end
