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
    {:ok, response} = HTTPoison.get!(url, headers, options)
    Poison.decode!(response.body)
    # TODO: pagination; _links contains next page, etc.
  end

  def get_dataverse_records(url, set) do
    set_url = "#{url}?verb=ListRecords&set=#{set}&metadataPrefix=oai_datacite"
    {:ok, %{ body: body } } = HTTPoison.get!(set_url)

    body
    |> xmap(
      records: [
        ~x"//ListRecords/record"l,
        identifier: ~x"//header/identifier/text()"
      ],
      resumptionToken: ~x"//resumptionToken/text()"
    )
    |> extract_records
  end

  def extract_records(map=%{records: records, resumptionToken: token}) do
    records
  end

  def extract_records(map=%{records: records}) do
    Map.append(records)
  end

end
