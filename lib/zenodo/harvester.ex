defmodule Zenodo do
  defmodule Harvester do
    def get_zenodo_records(search_url) do
      ZenodoApiStream.response_pages(search_url: search_url)
      |> Enum.flat_map(&parse_zenodo_records/1)
    end

    def get_zenodo_fields(search_url) do
      ZenodoApiStream.response_pages(search_url: search_url)
      |> Enum.reduce([], &accumulate_fields/2)
      |> Enum.uniq
    end

    defp parse_zenodo_records(body) do
      get_hits(body)
      |> Enum.map(fn record -> %{ identifier: "doi:#{record["doi"]}" } end)
    end

    # map is the whole page response body
    defp accumulate_fields(map, fields_list) do
      get_hits(map)
      |> Enum.reduce(fields_list, fn m, acc -> acc ++ extract_fields(m) end)
    end

    defp extract_fields(value) when is_map(value) do
      Map.keys(value)
      |> Enum.flat_map(fn key -> extract_fields(key, value[key]) end)
    end

    defp extract_fields(key, value) when is_map(value) do
      Map.keys(value)
      |> Enum.flat_map(fn x -> extract_fields(x, value[x]) end)
      |> Enum.map(fn x -> "#{key}:#{x}" end)
    end

    defp extract_fields(key, value) when is_list(value) do
      value
      |> Enum.flat_map(fn x -> extract_fields(key, x) end)
    end

    defp extract_fields(key, value) do
      [key]
    end

    defp get_hits(zenodo_respose) do
      zenodo_respose
      |> Map.fetch!("hits")
      |> Map.fetch!("hits")
    end
  end
end
