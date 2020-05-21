defmodule ResearchDataHarvesterTest do
  use ExUnit.Case
  import Mock

  describe "#get_dryad_records" do
    test "returns parsed json of Princeton University records" do
      url = "https://datadryad.org/api/v2/datasets"
      body = File.read!("test/fixtures/dryad_records_page_1.txt")

      get_mock = fn url, _params, _headers ->
        {
          :ok,
          %HTTPoison.Response{
            body: body,
            status_code: 200
          }
        }
      end

      json =
        Mock.with_mock HTTPoison, get!: get_mock do
          ResearchDataHarvester.get_dryad_records()
        end

      assert Map.keys(json) == ["_embedded", "_links", "count", "total"]
      assert json["count"] == 10
      assert json["total"] == 33511
    end
  end

  describe "#get_dataverse_records" do

    def mock_dataverse_records("https://dataverse.harvard.edu/oai?verb=ListRecords&set=Princeton_Authored_Datasets&metadataPrefix=oai_datacite") do
      body = File.read!("test/fixtures/dataverse/dataverse_page_1.xml")
      {
        :ok,
        %HTTPoison.Response{
          body: body,
          status_code: 200
        }
      }
    end

    def mock_dataverse_records("https://dataverse.harvard.edu/oai?verb=ListRecords&resumptionToken=MToxMDB8MjpBZnJpY2FSaWNlfDM6fDQ6fDU6b2FpX2RhdGFjaXRl") do
      body = File.read!("test/fixtures/dataverse/dataverse_page_2.xml")
      {
        :ok,
        %HTTPoison.Response{
          body: body,
          status_code: 200
        }
      }
    end

    test "returns a data struct for each record" do
      url = "https://dataverse.harvard.edu/oai"
      set = "Princeton_Authored_Datasets"
      output =
        Mock.with_mock HTTPoison, get!: &mock_dataverse_records/1 do
          ResearchDataHarvester.get_dataverse_records(url, set)
        end

      # get 2 pages
      assert length(output) == 200
    end
  end
end
