class PromoDemo
  
  def self.campaigns
    [{:name => "Under Cap-Coke", :subs => ["East", "West"]},
     {:name => "Under Cap-Pepsi", :subs => ["North", "West", "South"]},
     {:name => "Promotional Discount 50%", :subs => ["US", "CAN"]},
     {:name => "Doritos on package"},
     {:name => "Nestle Wrapper"},
     {:name => "P&G Peel Off"}
      ]
  end
  
  def self.list
    a = []
    campaigns.each do |x|
      a << x[:name]
    end
    a
  end
  
  def self.campaign(name)
    campaigns.select{|x| x[:name] == name}.first
  end

  def self.randomize
    i = campaigns.size
    rand = rand(i)
    campaigns[rand]
  end
  
  def self.add_sale(args={})
    account_obj = args[:account]
    num = args[:num]
    runcode = args[:runcode]
    campaign = args[:campaign]    
    inbound = Inbound.new
    inbound.account_id = account_obj.id
    inbound.file_name = "no file"
    inbound.run_code = runcode
    inbound.rec_type = "Promo"
    inbound.save
    for i in 1..num do
      this_line = Gmg::LineItem.new
      this_line.merchant = campaign[:name]
      this_line.marketing_code = campaign[:subs] ? campaign[:subs][rand(campaign[:subs].size)] : ""
      #random amt = 5,10,15
      amt = ["5","10","15"][rand(3)]
      this_line.product = "PROMO-GMG-#{amt}"
      this_line.serial = "#{runcode}#{rand(1000000)}#{i}"
      r = runcode.to_s
      this_line.date = "#{r[0..3]}-#{r[4..5]}-#{r[6..7]}"
      this_line.time = "12:00"
      this_line.amount = amt.to_d
      this_line.currency = "USD"
      sale = this_line.process_promo(inbound, runcode)
      #puts sale.inspect
    end   
  end
  
  def self.redeem(args={})
    account_obj = args[:account]
    num = args[:num]
    runcode = args[:runcode]
    campaign = args[:campaign]
    inbound = Inbound.new
    inbound.account_id = account_obj.id
    inbound.file_name = "no file"
    inbound.run_code = runcode
    inbound.rec_type = "Promo Redeem"
    inbound.save
    for i in 1..num
      
      this_sale = Sale.find(:all,
                      :readonly => false,
                      :joins => "JOIN inbounds on inbounds.id = sales.inbound_id 
                                             JOIN accounts on accounts.id = inbounds.account_id
                                             JOIN retailers on retailers.id = sales.retailer_id",
                      :conditions => ["sales.rec_type = 'Promo' and accounts.id = ? and was_redeemed is null and merchant = ?", 
                        account_obj.id, campaign[:name]]).first
      
      if this_sale
        red = Redemption.new(:serial_number => this_sale.serial_number,
                          :amount => this_sale.amount,
                          :product => this_sale.product,
                          :inbound_id => inbound.id,
                          :item_date => Date.today.strftime("%Y-%m-%d"),
                          :item_time => "12:00",
                          :item_year => Date.today.strftime("%Y"),
                          :item_month => Date.today.strftime("%m"),
                          :item_day => Date.today.strftime("%d"),
                          :sale_id => this_sale.id)
        
        if red.save
          this_sale.update_attributes!(:was_redeemed => true)
          this_sale.redemption = red
          this_sale.save
        end
      end
    end
  end
  
  
  def self.clear_runcode(args={})
    account_obj = args[:account]
    runcode = args[:runcode]
    inbounds = Inbound.all(:conditions => ["account_id = ? and run_code = ?", account_obj.id, runcode.to_i])
    inbounds.each do |inb|
      inb.sales.each do |s|
        if s.redemption
          s.redemption.destroy
        end
        s.destroy
      end
      inb.destroy
    end
  end
  
end