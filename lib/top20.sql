select * from 
 (
( select * from
(SELECT (@rownum:=@rownum + 1) AS myrank,
merchant,
total
FROM ( SELECT merchant,
SUM(day_total) AS total
FROM {{@dash1}}
WHERE partner = "Facebook"
GROUP BY 1
) AS merchants,
(SELECT @rownum := 0) r
ORDER BY total DESC) z
where myrank <= 20 ) x
right join 
(
select sum(amount) day_total, sum(f1) count_of_items, f3 merchant, ds, f2 partner
from temp_ps 
where p_type='Periscope Retailer 180'
and ds > DATE_FORMAT(CURRENT_DATE - INTERVAL 31 DAY, '%Y-%m-%d')
group by f2, ds, f3
order by ds, sum(amount) desc
) y on x.merchant = y.merchant )
