CREATE PROC usp_generate_writertv
AS
BEGIN
	MERGE fact_outcome as target
	using
	(
		SELECT id_initiative, id_media_type,id_dim_date, 2 as id_type, sum(value)  as value
		FROM 
		(
			SELECT  di.id as id_initiative ,  
			CASE WHEN st.media = 'Other' then (select top 1 id from dim_media_type where media_type = 'OOH') 
			else (SELECT TOP 1 id from dim_media_type where media_type = 'TV') 
			END AS id_media_type
			, d.id_dim_date
			,convert(money,st.[billable]) as value
			FROM STG_TV_Writer st
			JOIN STG_writerdigital_match sm on st.estimate = sm.estimate
			join dim_media_type dm on dm.media_type = 'TV'
			join dim_initiative di on di.initiative_name = sm.initiative
			join month_names mn on mn.month_name = LEFT(st.month,3)
			JOIN Dim_Date d on d.year = CONVERT (int, '20'+ right(st.month,2)) and d.month = mn.id
			join GlobalParameters g on  ltrim(rtrim(str(d.year))) + rtrim(ltrim(replace(str(d.month,2),space(1),'0'))) > ltrim(rtrim(str(g.CurrentYear))) + rtrim(ltrim(replace(str(g.currentmonth,2),space(1),'0')))
		) AS x
		GROUP BY id_initiative, id_media_type, id_dim_date
	) as source on source.id_initiative = target.id_initiative and source.id_media_type = target.id_media_type and source.id_dim_date = target.id_time
	WHEN NOT MATCHED THEN 
		INSERT (id_initiative, id_media_type, value, id_time, id_type) values (source.id_initiative, source.id_media_type, source.value,source.id_dim_date, source.id_type)
	WHEN MATCHED THEN 
		UPDATE set target.value = source.value;

END