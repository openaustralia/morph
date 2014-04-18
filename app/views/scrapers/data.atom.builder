xml.instruct! :xml, :version => "1.0"
xml.feed :xmlns => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.title "Morph: #{@scraper.full_name}"
  xml.subtitle @scraper.description
  xml.updated DateTime.parse(@scraper.updated_at.to_s).rfc3339
  xml.author do
    xml.name @scraper.owner.name || @scraper.owner.nickname
  end
  xml.id "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  xml.link href: scraper_url(@scraper)
  xml.link href: "#{request.protocol}#{request.host_with_port}#{request.fullpath}", rel: "self"
  @result.each do |result|
    xml.entry do
      xml.title result['title']
      xml.content result['content']
      xml.link href: result['link']
      xml.id result['link']
      xml.updated DateTime.parse(result['date']).rfc3339 rescue nil
    end
  end
end
