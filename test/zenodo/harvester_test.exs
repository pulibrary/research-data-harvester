defmodule ZenodoHarvesterTest do
  use ExUnit.Case
  import Mock

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

  def mock_zenodo_records(
        "https://zenodo.org/api/records/?sort=bestmatch&q=creators.affiliation%3APrinceton&page=38&size=10"
      ) do
    body = File.read!("test/fixtures/zenodo/zenodo_page_38.json")

    {
      :ok,
      %HTTPoison.Response{
        body: body,
        status_code: 200
      }
    }
  end

  describe "#get_zenodo_records" do
    test "returns parsed json of Princeton University records" do
      search_url = "https://zenodo.org/api/records/?q=creators.affiliation%3APrinceton"

      output =
        Mock.with_mock HTTPoison, get: &mock_zenodo_records/1 do
          Zenodo.Harvester.get_zenodo_records(search_url)
        end

      assert length(output) == 20
      assert(hd(output).identifier) == "doi:10.5281/zenodo.822470"
    end
  end

  describe "#get_zenodo_fields" do
    test "gets field list" do
      search_url = "https://zenodo.org/api/records/?q=creators.affiliation%3APrinceton"

      output =
        Mock.with_mock HTTPoison, get: &mock_zenodo_records/1 do
          Zenodo.Harvester.get_zenodo_fields(search_url)
        end

      assert Enum.member?(output, "conceptdoi")
      assert Enum.member?(output, "links:badge")
      assert Enum.member?(output, "metadata:access_right")
      assert Enum.member?(output, "metadata:creators:affiliation")
      assert Enum.member?(output, "metadata:keywords")
    end
  end
end
