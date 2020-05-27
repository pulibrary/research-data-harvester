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
    base_url = "https://datadryad.org"
    path = "/api/v2/datasets"
    RestApiStream.response_pages(base_url: base_url, path: path)
    |> Enum.flat_map(&parse_dryad_records/1)
  end

  def parse_dryad_records(body) do
    body
    |> Map.fetch!("_embedded")
    |> Map.fetch!("stash:datasets")
    |> Enum.map(fn record -> %{ identifier: record["identifier"] } end)
  end

  def get_zenodo_records do
    search_url = "https://zenodo.org/api/records/?q=creators.affiliation%3APrinceton"
    Zenodo.Harvester.get_zenodo_records(search_url)
  end

  def get_dataverse_records(base_url, set) do
    OaiStream.oai_pages(base_url: base_url, set: set, metadata_prefix: "oai_datacite")
    |> Enum.flat_map(&parse_dataverse_records/1)
  end

  def parse_dataverse_records(body) do
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
