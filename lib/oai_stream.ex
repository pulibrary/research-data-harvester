import SweetXml

defmodule OaiStream do
  # Return a lazily evaluated stream of all OAI page bodies.
  def oai_pages(base_url, set) do
    Stream.resource(
      fn -> get_first_page(base_url, set) end,
      &get_next_page/1,
      fn(_state) -> end
    )
  end

  def get_first_page(base_url, set) do
    page_url = "#{base_url}?verb=ListRecords&set=#{set}&metadataPrefix=oai_datacite"
    {:ok, %{ body: body } } = HTTPoison.get!(page_url)
    token = body |> xpath(~x"//resumptionToken/text()")
    { [body], { base_url, token } }
  end

  def get_next_page({ base_url, nil}) do
    { :halt, [] }
  end

  # We have to get the first body in the first request, so this just pulls it
  # out and returns it to the stream so it can move on to the next pages.
  def get_next_page({ body, { base_url, token } }) do
    { body, { base_url, token } }
  end

  def get_next_page({ base_url, token}) do
    page_url = "#{base_url}?verb=ListRecords&resumptionToken=#{token}"
    {:ok, %{ body: body } } = HTTPoison.get!(page_url)
    token = body |> xpath(~x"//resumptionToken/text()")
    { [body], { base_url, token } }
  end

end
