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
    headers = ["Accept": "application/json", "Content-Type": "application/json"]
    options = [ssl: [{:versions, [:'tlsv1.2']}]]
    {:ok, response} = HTTPoison.get!(url, headers, options)
    Poison.decode!(response.body)
    # TODO: pagination; _links contains next page, etc.
  end
end
