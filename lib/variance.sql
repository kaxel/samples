DROP PROCEDURE  sp_generate_forecast;

DELIMITER //

CREATE PROCEDURE sp_generate_forecast (IN p_run_day INT(10), IN p_month INT(10), IN p_year INT(10), IN revplanid INT(10), IN month_days INT(10))
BEGIN
          DECLARE r_units, r_day, r_partner int;
          DECLARE done int DEFAULT 0;

      -- fields - partial_total day_ave retail_chg margin_chg
      -- retail_margin net_sales p_rev_share gross_margin
        -- clear out any previous forecast
          DELETE FROM revplan_infos
           WHERE revplan_id = revplanid
             AND (revplan_type = 'Forecast' OR revplan_type = 'Variance');

        -- enter Forecast
             INSERT INTO revplan_infos (partner_id, partial_total, revplan_id, revplan_type, 
                                         created_at, updated_at, retail_margin, net_sales, p_rev_share, 
                                         gross_margin, amount, day_ave, p_name)
             SELECT p.id partner_id
                  ,sum(s.amount) partial_total
                  ,revplanid
                  ,'Forecast'
                  ,SYSDATE()
                  ,SYSDATE()
                  ,-1 * (((sum(s.amount)/p_run_day) * month_days) * (p_info.retail_margin/100)) retail_margin
                  ,((sum(s.amount)/p_run_day) * month_days) - (((sum(s.amount)/p_run_day) * month_days) * (p_info.retail_margin/100)) net_sales
                  ,-1 * ((((sum(s.amount)/p_run_day) * month_days) - (((sum(s.amount)/p_run_day) * month_days) * (p_info.retail_margin/100))) * p_info.rev_share/100) p_rev_share
                  ,((((sum(s.amount)/p_run_day) * month_days) - (((sum(s.amount)/p_run_day) * month_days) * (p_info.retail_margin/100))) * ((100-p_info.rev_share)/100)) gross
                  ,(sum(s.amount)/p_run_day) * month_days forecast_total
                  ,(sum(s.amount)/p_run_day) day_ave
                  ,p.name
              	FROM sales s
				JOIN inbounds i ON i.id = s.inbound_id
				JOIN accounts a ON a.id = i.account_id
				JOIN partners p ON p.id = a.partner_id
				JOIN partner_infos p_info 
				                ON p_info.partner_id = p.id
             WHERE item_month = p_month
               AND item_year = p_year
               AND s.rec_type = 'Sales'
               AND p.p_type = 'Sales'
             GROUP BY p.name
             ORDER BY sum(s.amount) DESC;


        -- UPDATE REV PLAN
        UPDATE revplan_infos AS ri SET
      ri.retail_margin = -1 * (SELECT (ri.amount * partner_infos.retail_margin/100)
                                       FROM partner_infos
                                      WHERE ri.partner_id = partner_infos.partner_id),
      ri.net_sales     = (SELECT ri.amount - (ri.amount * partner_infos.retail_margin/100)
                                       FROM partner_infos
                                      WHERE ri.partner_id = partner_infos.partner_id),
      ri.p_rev_share   = -1 * (SELECT (ri.amount - (ri.amount * partner_infos.retail_margin/100)) * partner_infos.rev_share/100
                                       FROM partner_infos
                                      WHERE ri.partner_id = partner_infos.partner_id),
      ri.gross_margin  = (SELECT (ri.amount - (ri.amount * partner_infos.retail_margin/100)) * (100-partner_infos.rev_share)/100
                                       FROM partner_infos
                                      WHERE ri.partner_id = partner_infos.partner_id),
      ri.p_name        = (SELECT name FROM partners where partners.id = ri.partner_id)              
       WHERE revplan_id = revplanid
         AND revplan_type = 'Plan';

      INSERT INTO revplan_infos (partner_id, amount, revplan_id, revplan_type, retail_margin, net_sales, 
                                 p_rev_share, gross_margin, retail_chg, margin_chg, created_at, updated_at, p_name)
      SELECT t_plan.partner_id
            ,for_amount - plan_amount GROSS_RETAIL
            ,revplanid
            ,'Variance'
            ,(for_amount * p_infos.retail_margin/100) - (plan_amount * p_infos.retail_margin/100) RETAIL_MARGIN
            ,(for_amount - (for_amount * p_infos.retail_margin/100)) - (plan_amount - (plan_amount * p_infos.retail_margin/100))  NET_SALES
            ,((for_amount - (for_amount * p_infos.retail_margin/100)) * p_infos.rev_share/100) - ((plan_amount - (plan_amount * p_infos.retail_margin/100)) * p_infos.rev_share/100) P_REV_SHARE
            ,((for_amount - (for_amount * p_infos.retail_margin/100)) * (100-p_infos.rev_share)/100) - ((plan_amount - (plan_amount * p_infos.retail_margin/100)) * (100-p_infos.rev_share)/100) GROSS_MARGIN
            ,(((for_amount - (for_amount * p_infos.retail_margin/100)) * (100-p_infos.rev_share)/100) - ((plan_amount - (plan_amount * p_infos.retail_margin/100)) * (100-p_infos.rev_share)/100))/plan_amount RETAIL_CHG
            ,(((for_amount - (for_amount * p_infos.retail_margin/100)) * (100-p_infos.rev_share)/100) - ((plan_amount - (plan_amount * p_infos.retail_margin/100)) * (100-p_infos.rev_share)/100))/t_plan.gross_margin MARGIN_CHG
            ,SYSDATE()
            ,SYSDATE()
            ,p.name
        FROM     
         (SELECT partner_id, amount plan_amount, gross_margin 
            FROM revplan_infos 
           WHERE revplan_type = 'Plan'
             AND revplan_id = revplanid) t_plan
        JOIN (
          SELECT partner_id, amount for_amount 
            FROM revplan_infos 
           WHERE revplan_type = 'Forecast'
             AND revplan_id = revplanid) t_for 
          ON t_for.partner_id = t_plan.partner_id
        JOIN partner_infos p_infos 
          ON p_infos.partner_id = t_plan.partner_id
        JOIN partners p 
          ON p.id = t_plan.partner_id;

-- add faux forecast

	  INSERT INTO revplan_infos (partner_id, amount, revplan_id, revplan_type, retail_margin, net_sales, 
		                                 p_rev_share, gross_margin, retail_chg, margin_chg, created_at, updated_at, p_name,
		                                 partial_total, day_ave)
	  SELECT pivot.partner_id, 0, pivot.revplan_id, 'Forecast', 0, 0, 0, 0, null, null, SYSDATE(), SYSDATE(), part.name, 0, 0 from
		(
		SELECT p.partner_id, p.revplan_id, f.partner_id missing from 
		(SELECT partner_id, revplan_id, revplan_type from revplan_infos
		where revplan_type = 'Plan'
		and revplan_id = revplanid) p left JOIN
		(SELECT partner_id, revplan_id, revplan_type from revplan_infos
		where revplan_type = 'Forecast'
		and revplan_id = revplanid) f  ON f.partner_id = p.partner_id and f.revplan_id = p.revplan_id
		) pivot join partners part on part.id = pivot.partner_id
		where missing is null;

-- add faux variance

	  INSERT INTO revplan_infos (partner_id, amount, revplan_id, revplan_type, retail_margin, net_sales, 
				                         p_rev_share, gross_margin, retail_chg, margin_chg, created_at, updated_at, p_name)
	  SELECT pivot.partner_id, 0, pivot.revplan_id, 'Variance', 0, 0, 0, 0, 0, 0, SYSDATE(), SYSDATE(), part.name from
		(
		SELECT p.partner_id, p.revplan_id, f.partner_id missing from 
		(SELECT partner_id, revplan_id, revplan_type from revplan_infos
		where revplan_type = 'Plan'
		and revplan_id = revplanid) p left JOIN
		(SELECT partner_id, revplan_id, revplan_type from revplan_infos
		where revplan_type = 'Variance'
		and revplan_id = revplanid) f  ON f.partner_id = p.partner_id and f.revplan_id = p.revplan_id
		) pivot join partners part on part.id = pivot.partner_id
		where missing is null;
				
END //

DELIMITER ;
