module CurrencyCode
    
  def country_name_from_code(code)
    #seems only needed for Eurozone countries (anythying where country name cannot be inferred from currency code)
    members = [
      :deu => "Germany",
      :ire => "Ireland",
      :irl => "Ireland",
      :fra => "France",
      :aut => "Austria",
      :fin => "Finland",
      :ita => "Italy",
      :nor => "Norway",
      :esp => "Spain",
      :bel => "Belgium",
      :nld => "Netherlands"
      ]
      
    s = code.downcase.to_sym
    members.find{|x| x.keys.include?(s)} ? members.select{|x| x.keys.include?(s)}[0][s] : nil
  end
  
  def c_code_name(codename)
    get_list.any? {|t| t[:currency_code] == codename.to_s} ? get_list.select {|t| t[:currency_code] == codename.to_s}[0][:country_name] : "error"
  end
  
  def c_name_currency(country_name)
    get_list.any? {|t| t[:country_name] == country_name.to_s} ? get_list.select {|t| t[:country_name] == country_name.to_s}[0][:currency_code] : "error"
  end
  
  def get_list
    [
      {:country_name => "Argentina",          :currency_code => "ARS"},
      {:country_name => "Colombia",           :currency_code => "COP"},
      {:country_name => "Chile",              :currency_code => "CLP"},
      {:country_name => "Costa Rica",         :currency_code => "CRC"},
      {:country_name => "Dominican Republic", :currency_code => "DOP"},
      {:country_name => "Honduras",           :currency_code => "HNL"},
      {:country_name => "Nicaragua",          :currency_code => "NIO"},
      {:country_name => "Paraguay",           :currency_code => "PYG"},
      {:country_name => "Peru",               :currency_code => "PEN"},
      {:country_name => "Uruguay",            :currency_code => "UYU"},
      {:country_name => "Venezuela",          :currency_code => "VEF"},
      {:country_name => "Bolivia",            :currency_code => "BOB"},
      {:country_name => "Cuba",               :currency_code => "CUP"},
      {:country_name => "Guatemala",          :currency_code => "GTQ"},
      {:country_name => "Haiti",              :currency_code => "HTG"},
      {:country_name => "United Kingdom",     :currency_code => "GBP"},
      {:country_name => "USA",                :currency_code => "USD"},
      {:country_name => "Australia",          :currency_code => "AUD"},
      {:country_name => "New Zealand",        :currency_code => "NZD"},
      {:country_name => "Canada",             :currency_code => "CAD"},
      {:country_name => "Norway",             :currency_code => "NOK"},
      {:country_name => "Switzerland",        :currency_code => "CHF"},
      {:country_name => "Sweden",             :currency_code => "SEK"},
      {:country_name => "Denmark",            :currency_code => "DKK"},
      {:country_name => "European Union",     :currency_code => "EUR"},
      {:country_name => "Mexico",             :currency_code => "MXN"},
      {:country_name => "Brazil",             :currency_code => "BRL"},
      {:country_name => "Turkey",             :currency_code => "TRY"},
      {:country_name => "Great Britain",      :currency_code => "GBP"},
      {:country_name => "Russia",             :currency_code => "RUB"},
      {:country_name => "Japan",              :currency_code => "JPY"},
      {:country_name => "Malaysia",           :currency_code => "MYR"},
      {:country_name => "Philippines",        :currency_code => "PHP"},
      {:country_name => "Taiwan",             :currency_code => "TWD"},
      {:country_name => "Hong Kong",          :currency_code => "HKD"},
      {:country_name => "Thailand",           :currency_code => "THB"},
      {:country_name => "Indonesia",          :currency_code => "IDR"},
      {:country_name => "India",              :currency_code => "INR"},
      {:country_name => "China",              :currency_code => "CNY"},
      {:country_name => "Singapore",          :currency_code => "SGD"},
      {:country_name => "South Korea",        :currency_code => "KRW"}
    ]
  end
  
  def round_to_x(in_x, x)
    begin
      (in_x * 10**x).round.to_f / 10**x
    rescue
      puts "problem rounding #{in_x} to #{x}"
    end
  end
  
end