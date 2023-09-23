INSERT INTO generation_capture (
       time,
       area_id,
       production_type_id,
       price,

       kwh,
       kwh_generated,
       kwh_consumed,

       revenue,
       revenue_generated,
       revenue_consumed
)
-- Calculate kWh
SELECT
	time_bucket('1h',g.time) AS time,
	g.area_id,
	g.production_type_id,
	AVG(p.value) AS price,

	AVG(g.value) AS kwh,
        AVG(GREATEST(0,g.value)) AS kwh_generated,
        AVG(LEAST(0,g.value)) AS kwh_consumed,

	-- price per mwh / kwh !!
	AVG(p.value::bigint*g.value)/1000 AS revenue,
        AVG(p.value::bigint*GREATEST(0,g.value))/1000 AS revenue_generated,
        AVG(p.value::bigint*LEAST(0,g.value))/1000 AS revenue_consumed
FROM generation g
INNER JOIN prices p ON(g.area_id=p.area_id AND g.time=p.time)
-- Joins for WHERE clause
INNER JOIN areas a ON(g.area_id=a.id)
INNER JOIN production_types pt ON(g.production_type_id=pt.id)
WHERE
	a.source='aemo' AND
	pt.name <> 'solar_rooftop' AND
	pt.name NOT LIKE 'battery%' AND
	pt.name NOT LIKE 'hydro%'
	--g.time BETWEEN '2023-05-01' AND '2023-06-01' AND a.code='QLD1'
GROUP BY 1,2,3
ON CONFLICT ON CONSTRAINT generation_capture_pkey DO UPDATE SET
   price = EXCLUDED.price,
   kwh = EXCLUDED.kwh,
   kwh_generated = EXCLUDED.kwh_generated,
   kwh_consumed = EXCLUDED.kwh_consumed,
   revenue = EXCLUDED.revenue,
   revenue_generated = EXCLUDED.revenue_generated,
   revenue_consumed = EXCLUDED.revenue_consumed
;