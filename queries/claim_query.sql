SELECT COUNT(number) as Count, jurisdictionId as Jurisdiction, extract(month from createddate) as Month, extract(year from createddate) as Year
FROM db.claim
WHERE status != 'Pending'
GROUP BY jurisdictionId, extract(month from createddate), extract(year from createddate)
ORDER BY extract(year from createddate) desc, extract(month from createddate) desc, jurisdictionId asc