defmodule ResearchDataHarvesterTest do
  use ExUnit.Case
  import Mock

  describe "#get_dryad_records" do
    test "returns parsed json of Princeton University records" do
      url = "https://datadryad.org/api/v2/datasets"
      body = File.read!("test/fixtures/dryad_records_page_1.txt")
      get_mock = fn url, _params, _headers ->
        {:ok,
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
end
