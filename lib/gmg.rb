include Utils
include CurrencyCode
module Gmg
  # this is the module for the gmg activator

  #STDOUT.sync = true | STDOUT.sync = STDERR.sync = true
  
  class LineItem <
    Struct.new(:merchant,
      :merchant_alias,
      :serial,
      :product,
      :amount,
      :date,
      :time,
      :location,
      :vendor,
      :city,
      :state,
      :zip,
      :country,
      :marketing_code,
      :currency,
      :dcmsid,
      :vc,
      :local_currency_amount,
      :local_currency_code,
      :fx_batch_id,
      :app_id,
      :payment_type,
      :currency_url,
      :currency_title,
      :currency_description,
      :payment_rate,
      :application_name,
      :developer_name,
      :redemption_p_source,
      :date_last_activated
      )
      #originally copied from incomm.rb
    def month
      date.split("-")[1].to_i
    end   
    def year
      date.split("-")[0].to_i
    end
    def day
      date.split("-")[2].to_i
    end
    
    
    def process_promo(inbound, runcode)
      
      if currency != "USD"
        orig_amount = amount
        rate = ERate.latest(currency, runcode)
        new_amount = orig_amount * rate
        puts "erate:#{rate} new_amount:#{new_amount} from orig_amount:#{orig_amount}"
      else
        new_amount = amount
        orig_amount = amount
      end
      
      #find retailer or add new one
      retailer = Retailer.find_by_merchant_and_location(merchant, location)
      if !retailer
        retailer = Retailer.create!(:merchant => merchant, :merchant_alias => merchant_alias, :location => location,
                                    :city => city, :state => state, :country_name => country, :currency_code => currency)
        #puts "retailer created\n"
      else
        #puts "retailer found\n"
      end
      
      x = Sale.new(:amount => new_amount,
                   :orig_amount => orig_amount,
                   :serial_number => serial,
                   :inbound_id => inbound.id,
                   :run_code => runcode,
                   :product => product,
                   :item_date => date,
                   :rec_type => "Promo",
                   :item_time => time,
                   :item_year => year,
                   :item_month => month,
                   :item_day => day,
                   :currency_code => currency,
                   :marketing_code => marketing_code,
                   :dcmsid => dcmsid,
                   :retailer => retailer)
      if x.save
        x
      else
        "error"
      end
    end
  end
  
  def self.list_of_optional_redemption_fields
    ['LocalCurrencyAmount',
     'LocalCurrencyCode',
     'FxBatchId',
     'AppID',
     'PaymentType',
     'CurrencyUrl',
     'CurrencyTitle',
     'CurrencyDescription',
     'PaymentRate',
     'ApplicationName',
     'DeveloperName',
     'RedemptionPSource',
     'DateLastActivated']
  end

end