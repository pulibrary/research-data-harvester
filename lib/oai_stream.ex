import SweetXml

defmodule OaiStream do
  # Return a lazily evaluated stream of all OAI page bodies.
  def oai_pages(base_url: base_url, set: set, metadata_prefix: metadata_prefix) do
    Stream.resource(
      fn -> { base_url, set, metadata_prefix } end,
      &get_page/1,
      fn(_state) -> end
    )
  end

  # If given a metadata_prefix, it's the first page.
  def get_page({ base_url, set, metadata_prefix }) do
    page_url = "#{base_url}?verb=ListRecords&set=#{set}&metadataPrefix=#{metadata_prefix}"
    {:ok, %{ body: body } } = HTTPoison.get!(page_url)
    token = body |> xpath(~x"//resumptionToken/text()")
    { [body], { base_url, token } }
  end

  # If the resumption token is nil there's no more pages to get.
  def get_page({ _base_url, _token = nil}) do
    { :halt, [] }
  end

  # If there's a resumption token get the next page and return its body.
  def get_page({ base_url, token}) do
    page_url = "#{base_url}?verb=ListRecords&resumptionToken=#{token}"
    {:ok, %{ body: body } } = HTTPoison.get!(page_url)
    token = body |> xpath(~x"//resumptionToken/text()")
    { [body], { base_url, token } }
  end

end
