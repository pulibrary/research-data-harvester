defmodule Zenodo do
  defmodule Harvester do
    def get_zenodo_records(search_url) do
      ZenodoApiStream.response_pages(search_url: search_url)
      |> Enum.flat_map(&parse_zenodo_records/1)
    end

    def get_zenodo_fields(search_url) do
      ZenodoApiStream.response_pages(search_url: search_url)
      |> Stream.flat_map(&get_hits/1)
      |> Stream.flat_map(&extract_fields/1)
      |> Stream.uniq
      |> Enum.to_list
    end

    defp parse_zenodo_records(body) do
      get_hits(body)
      |> Stream.map(fn record -> %{ identifier: "doi:#{record["doi"]}" } end)
    end

    defp extract_fields(value) when is_map(value) do
      Map.keys(value)
      |> Stream.flat_map(fn key -> extract_fields(key, value[key]) end)
    end

    defp extract_fields(key, value) when is_map(value) do
      Map.keys(value)
      |> Stream.flat_map(fn x -> extract_fields(x, value[x]) end)
      |> Stream.map(fn x -> "#{key}:#{x}" end)
    end

    defp extract_fields(key, value) when is_list(value) do
      value
      |> Stream.flat_map(fn x -> extract_fields(key, x) end)
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
