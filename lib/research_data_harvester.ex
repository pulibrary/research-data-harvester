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

  def get_dataverse_records(base_url, set) do
    "#{base_url}?verb=ListRecords&set=#{set}&metadataPrefix=oai_datacite"
    |> get_pages(base_url)
    |> Map.get(:records)
  end

  # Get first page.
  def get_pages(set_url, base_url) do
    {:ok, %{ body: body } } = HTTPoison.get!(set_url)

    body
    |> parse_records
    |> get_next_page(base_url)
  end

  def get_next_page(results = %{resumptionToken: nil}, _base_url) do
    results
  end
  def get_next_page(page = %{records: records, resumptionToken: token}, base_url) do
    page_url = "#{base_url}?verb=ListRecords&resumptionToken=#{token}"
    {:ok, %{ body: body } } = HTTPoison.get!(page_url)

    next_page = body
                |> parse_records
    page
    |> Map.put(:records, records ++ next_page.records)
    |> Map.put(:resumptionToken, next_page.resumptionToken)
    |> get_next_page(base_url)
  end

  def parse_records(body) do
    body
    |> xmap(
      records: [
        ~x"//ListRecords/record"l,
        identifier: ~x"//header/identifier/text()"
      ],
      resumptionToken: ~x"//resumptionToken/text()"
    )
  end
end
