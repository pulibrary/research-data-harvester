defmodule RestApiStream do
  # Return a lazily evaluated stream of all API response page bodies.
  def response_pages(base_url: base_url, path: path) do
    Stream.resource(
      fn -> { base_url, path } end,
      &get_page/1,
      fn(_state) -> end
    )
  end

  # If the resumption token is nil there's no more pages to get.
  def get_page({ _base_url, _path = nil}) do
    { :halt, [] }
  end

  def get_page({ base_url, path }) do
    page_url = "#{base_url}#{path}"
    headers = [Accept: "application/json", "Content-Type": "application/json"]
    options = [ssl: [{:versions, [:"tlsv1.2"]}]]
    {:ok, %{ body: body } } = HTTPoison.get!(page_url, headers, options)
    json = body
    |> Poison.decode!
    next_path = json
    |> Map.fetch!("_links")
    |> Map.get("next", %{})
    |> Map.get("href", nil)
    results = json
    |> Map.fetch!("_embedded")
    |> Map.fetch!("stash:datasets")
    { results, { base_url, next_path } }
  end
end
