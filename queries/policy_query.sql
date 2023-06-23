SELECT extract(month from effective_date) as Effective_Month, extract(year from effective_date) as Effective_Year ,COUNT(CASE WHEN policy_type_code = 'New' THEN 1 ELSE NULL END) AS New ,COUNT(CASE WHEN policy_type_code = 'Renewal' THEN 1 ELSE NULL END) AS Renewal ,COUNT(policy_uid) as Total
FROM db.policy
WHERE policy_suffix NOT LIKE '%bad%'
GROUP BY extract(month from effective_date), extract(year from effective_date)
ORDER BY extract(year from effective_date) desc, extract(month from effective_date) desc