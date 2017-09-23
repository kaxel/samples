DROP PROCEDURE  sp_populate_denom;

DELIMITER //

CREATE PROCEDURE sp_populate_denom ( )

BEGIN

  DECLARE v_year INT;

  DELETE FROM denoms where year(item_date)=year(curdate());
   
  INSERT INTO denoms (merchant, tag, total, count, item_date, partner, country, product, created_at)

  select 
                       merchant
                       ,concat(currency_code, ' ', denomination) denom
                       ,sum(total) total
                       ,sum(countx) count
                       , item_date
                       , display_val partner
                       , country
                       , product
					   , CURDATE()
       from
       (
       select	sum(case amount > 0 when true then 1 else -1 end) countx,	CASE true WHEN CHAR_LENGTH(merchant_alias) > 0 then merchant_alias ELSE merchant END merchant, sum(s.amount) total, 
               CASE true WHEN orig_amount IS NOT NULL then abs(orig_amount) ELSE abs(amount) END denomination, item_date, p.display_val, s.currency_code, r.country_name country, s.product
        from sales s
         JOIN inbounds i ON i.id = s.inbound_id
         JOIN accounts a ON a.id = i.account_id
         JOIN partners p on p.id = a.partner_id
         JOIN retailers r on r.id = s.retailer_id
        where s.rec_type = 'Sales'
        and s.retailer_id = r.id
		and year(item_date) = year(curdate())
        group by display_val, CASE true WHEN CHAR_LENGTH(merchant_alias) > 0 then merchant_alias ELSE merchant END, abs(amount), CASE true WHEN orig_amount IS NOT NULL then abs(orig_amount) ELSE abs(amount) END, item_date, s.currency_code, r.country_name, product
       having sum(s.amount) > 0
        order by sum(s.amount) desc 
       ) x
       group by display_val, merchant, denomination, item_date, currency_code, country, product
       order by merchant, denomination, count desc;

END //

DELIMITER ;
