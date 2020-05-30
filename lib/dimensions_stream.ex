defmodule DimensionsApiStream do
  # Return a lazily evaluated stream of all API response page bodies.
  def response_pages(base_url: base_url, token: token, limit: limit) do
    Stream.resource(
      fn -> {base_url, token, limit, 0} end,
      &get_page/1,
      fn _state -> nil end
    )
  end

  # If the offset is nil there are no more pages to get.
  def get_page({_base_url, _token, _limit, _offset = nil}) do
    {:halt, []}
  end

  # return a page of json at a time, caller should pull records
  def get_page({base_url, token, limit, offset}) do
    headers = [
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: "JWT #{token}"
    ]

    options = [ssl: [{:versions, [:"tlsv1.2"]}]]

    request_body =
      "search datasets where research_orgs=\"grid.16750.35\" return datasets[all] limit #{limit} skip #{offset}"

    {:ok, %{body: body}} = HTTPoison.post(base_url, request_body, headers, options)

    json =
      body
      |> Poison.decode!()

    datasets_count =
      json
      |> Map.fetch!("datasets")
      |> Enum.count()

    next_offset =
      if datasets_count == 0 do
        nil
      else
        offset + limit
      end

    {[json], {base_url, token, limit, next_offset}}
  end
end
