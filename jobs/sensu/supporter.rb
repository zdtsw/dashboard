require 'json'
require 'nokogiri'
require 'rest-client'
require 'date'

private
def read_confluence(xpath)
  #update below url for the page you want to check out, detail see documentation from confluence
  url = "https://confluence.mycompany.com/rest/api/content/1111111111?expand=body.view"
  begin
    #update my_user_id and my_user_pws with your own value
    response = RestClient::Request.execute(:url => url, :user => 'my_user_id', :password => 'my_user_psw', :method => :get)
    json = JSON.parse(response.to_str)
    return get_upcoming_entry_from_html(json['body']['view']['value'].to_s, xpath)
  rescue
    print "Rescue when getting table content from #{url}"
  end
end

private
def get_upcoming_entry_from_html(html_string, position)
  doc = Nokogiri::HTML(html_string)
  doc.xpath(position).each do |tr|
    array = []
    tr.xpath('td').each do |cell|
      array << cell.text
    end
    days_between = (Date.parse(array[0]) - Date.today).to_i
    if days_between < 7 and days_between >= 0
      return array[1]
    end
  end
end

SCHEDULER.every '5m', :first_in => 0 do
  #you might need to update below line for the html table format you have from your confluence page
  send_event('supportlist', { text: read_confluence('(//table)[1]//tbody//tr[position()>1]') })
end
