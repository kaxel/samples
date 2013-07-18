desc 'money scripts.'

include Utils
require 'net/ftp'
require 'open-uri'

namespace :money do

  task :get_rates do
    runcode_to_use = today_runcode

    list = CurrencyCode.get_list

    list.each do |x|
      symbol_lookup = "#{x[:currency_code]}USD"
      base_url = "http://download.finance.yahoo.com/d/quotes.csv?s=#{symbol_lookup}=X&f=sl1d1t1ba&e=.csv"
      http_response = Net::HTTP.get_response(URI.parse(base_url))  
      rate = http_response.body.scan(/,(\d{1,5}.\d{1,7})/)[0]
      final_rate = CurrencyCode.round_to_x(rate.to_s.to_f, 5)
      puts "#{final_rate} #{x[:currency_code]} to 1 USD"
      save = ERate.create!(:code=>x[:currency_code], :run_code => runcode_to_use, :value =>final_rate)
      puts "saved new erate id #{save.id} for code #{save.code} runcode #{save.run_code}"
    end
  end

end
