defmodule ResearchDataHarvesterTest do
  use ExUnit.Case
  import Mock

  describe "#get_dryad_records" do
    def mock_dryad_records("https://datadryad.org/api/v2/datasets", _headers, _options) do
      body = File.read!("test/fixtures/dryad/dryad_page_1.json")
      {
        :ok,
        %HTTPoison.Response{
          body: body,
          status_code: 200
        }
      }
    end

    def mock_dryad_records("https://datadryad.org/api/v2/datasets?page=3355", _headers, _options) do
      body = File.read!("test/fixtures/dryad/dryad_page_3355.json")
      {
        :ok,
        %HTTPoison.Response{
          body: body,
          status_code: 200
        }
      }
    end

    test "returns parsed json of Princeton University records" do

      output =
        Mock.with_mock HTTPoison, get!: &mock_dryad_records/3 do
          ResearchDataHarvester.get_dryad_records()
        end

      assert length(output) == 12
      assert(hd(output).identifier) == "doi:10.5061/dryad.7rh4625"
    end
  end

  describe "#get_zenodo_records" do
    def mock_zenodo_records("https://zenodo.org/api/records/?q=creators.affiliation%3APrinceton") do
      body = File.read!("test/fixtures/zenodo/zenodo_page_1.json")
      {
        :ok,
        %HTTPoison.Response{
          body: body,
          status_code: 200
        }
      }
    end

    def mock_zenodo_records("https://zenodo.org/api/records/?sort=bestmatch&q=creators.affiliation%3APrinceton&page=38&size=10") do
      body = File.read!("test/fixtures/zenodo/zenodo_page_38.json")
      {
        :ok,
        %HTTPoison.Response{
          body: body,
          status_code: 200
        }
      }
    end

    test "returns parsed json of Princeton University records" do
      output =
        Mock.with_mock HTTPoison, get: &mock_zenodo_records/1 do
          ResearchDataHarvester.get_zenodo_records()
        end

      assert length(output) == 20
      assert(hd(output).identifier) == "doi:10.5281/zenodo.822470"
    end

    test "get field list" do
      output =
        Mock.with_mock HTTPoison, get: &mock_zenodo_records/1 do
          ResearchDataHarvester.get_zenodo_fields()
        end

      assert Enum.member?(output, "metadata:creators:affiliation")
      # assert output == ["conceptdoi", "conceptrecid", "created", "doi", "files", "id", "links", "metadata:creators:affiliation", "metadata:creators:name" "owners", "revision", "stats", "updated"]
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
      assert length(output) == 144
      assert(hd(output).identifier) == "doi:10.7910/DVN/0SQFGQ"
    end
  end
end
