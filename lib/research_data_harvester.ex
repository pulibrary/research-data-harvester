import SweetXml

defmodule ResearchDataHarvester do
  @moduledoc """
  Documentation for ResearchDataHarvester.
  """

  @doc """
  Use the Dryad REST API to fetch all their dataset records and filter them for PU researchers

  See https://datadryad.org/api/v2/docs/#/default/get_datasets
  """
  def get_dryad_records do
    url = "https://datadryad.org/api/v2/datasets"
    headers = [Accept: "application/json", "Content-Type": "application/json"]
    options = [ssl: [{:versions, [:"tlsv1.2"]}]]
    {:ok, %{ body: body } } = HTTPoison.get!(url, headers, options)
    body
    |> Poison.decode!
    |> Map.fetch!("_embedded")
    |> Map.fetch!("stash:datasets")
    |> Enum.map(fn record -> %{ identifier: record["identifier"] } end)
    # TODO: pagination; _links contains next page, etc.
    # Map.keys(json) == ["_embedded", "_links", "count", "total"]
    # json["count"] == 10
    # json["total"] == 33511
  end

  def get_dataverse_records(base_url, set) do
    OaiStream.oai_pages(base_url: base_url, set: set, metadata_prefix: "oai_datacite")
    |> Enum.flat_map(&parse_records/1)
  end

  def parse_records(body) do
    body
    |> xmap(
      records: [
        ~x"//ListRecords/record"l,
        identifier: ~x"//header/identifier/text()"
      ]
    )
    |> Map.get(:records)
  end
end
