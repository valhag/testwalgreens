--	stored procedure name: usp_generate_puertorico
--	description: usp that generates (insert/update) data of fact_outcome for puerto rico file type
--	parameters: @executionID just to report success on validation/generation
--	author: HVA
--	Date Creation: 20/11/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date Modification: 24/01/2019 include id_time_generated
--	Date Modification: 25/01/2019 make sure @CURRENTMONTH must be compared correclty with single character months and change type file
--   Date Modification: 28/01/2019 include just valid initiatives-media types 
--   Date Modification: 02/10/2019 add previousdata
--   Date Modification: 02/13/2019 remove previousdata, implement changes to suppor fact_outcome_history_table
--   Date Modification: 02/18/2019 validate initiative media type apply months
--   Date Modification: 02/21/2019 CHANGE PUERTO RICO FILE
--   Date Modification: 02/28/2019 dim_wag_initiative new rows

--	drop PROC usp_generate_puertorico

--******************************************************* CREATE SP usp_generate_wag_initiative *******************************************************************************
CREATE PROC dbo.usp_generate_puertorico (
	@ExecutionID BIGINT
    ,@CURRENTYEAR AS INT
    ,@CURRENTMONTH AS INT) 
AS
BEGIN

	DECLARE @SUCCESSWITHOUTROWS AS INT

	DECLARE @tablepuertorico TABLE (
		ACTION VARCHAR(100)
	    ,id_Fact_Outcome INT
	    ,id_dim_date INT
	    ,value MONEY) 

	DECLARE @ID_DIM_DATE AS INT
	DECLARE @ID_MINDIM_DATE AS INT

	SELECT 
		@ID_MINDIM_DATE = MIN(id_dim_date)
	FROM 
		udf_dimdate (@CURRENTMONTH,@CURRENTYEAR) 
	SELECT 
		@ID_DIM_DATE = id_dim_date
	FROM 
		udf_dimdate (@CURRENTMONTH,@CURRENTYEAR)
	WHERE month = @CURRENTMONTH
		 AND year = @CURRENTYEAR

	IF OBJECT_ID('tempdb..##Month_id') IS NOT NULL
	BEGIN
		DROP TABLE ##Month_id
	END

	IF OBJECT_ID('tempdb..#STG_PuertoRico') IS NOT NULL
		DROP TABLE #STG_PuertoRico
	CREATE TABLE #STG_PuertoRico
	(
		 row_number INT
		,initiative nvarchar(500)
		,media_type nvarchar(500)
		,lawson nvarchar(500)
		,media_lawson nvarchar(500)
		,sep nvarchar(500)
		,oct nvarchar(500)
		,nov nvarchar(500)
		,dec nvarchar(500)
		,jan nvarchar(500)
		,feb nvarchar(500)
		,mar nvarchar(500)
		,apr nvarchar(500)
		,may nvarchar(500)
		,jun nvarchar(500)
		,jul nvarchar(500)
		,aug nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)

	INSERT INTO #STG_PuertoRico (
initiative
,lawson
,media_lawson
,media_type
,filename
,[row_number]
,apr
,aug
,dec
,feb
,jan
,jul
,jun
,mar
,may
,nov
,oct
,sep
	)
	select 
	initiative
,lawson
,media_lawson
,media_type
,filename
,[row_number]
,apr_mediacom_register
,aug_mediacom_register
,dec_mediacom_register
,feb_mediacom_register
,jan_mediacom_register
,july_mediacom_register
,june_mediacom_register
,mar_mediacom_register
,may_mediacom_register
,nov_mediacom_register
,oct_mediacom_register
,sept_mediacom_register
	from STG_PuertoRico
	

	--select * from #STG_PuertoRico

	CREATE TABLE ##Month_id (
		Seq_id INT
	    ,month_column_name NVARCHAR(25)
	    ,month_str NVARCHAR(5)) 

	INSERT INTO ##Month_id
	VALUES (
		  1
		 ,'sepstring'
		 ,'SEP'), (
		  2
		 ,'octstring'
		 ,'OCT'), (
		  3
		 ,'novstring'
		 ,'NOV'), (
		  4
		 ,'decstring'
		 ,'DEC'), (
		  5
		 ,'janstring'
		 ,'JAN'), (
		  6
		 ,'febstring'
		 ,'FEB'), (
		  7
		 ,'marstring'
		 ,'MAR'), (
		  8
		 ,'aprstring'
		 ,'APR'), (
		  9
		 ,'maystring'
		 ,'MAY'), (
		  10
		 ,'junstring'
		 ,'JUN'), (
		  11
		 ,'julstring'
		 ,'JUL'), (
		  12
		 ,'augstring'
		 ,'AUG') 

	IF OBJECT_ID('tempdb..##GlobalParamSeq') IS NOT NULL
	BEGIN
		DROP TABLE ##GlobalParamSeq
	END

	CREATE TABLE ##GlobalParamSeq (
		CurrentYear INT
	    ,CurrentMonth INT
	    ,CurrentMonthSTR NVARCHAR(3)
	    ,Seq_id INT) 

	INSERT INTO ##GlobalParamSeq
	SELECT 
		@CURRENTYEAR
	    ,@CURRENTMONTH
	    ,MI.month_str
	    ,mi.Seq_id
	FROM 
		##Month_id AS mi
		JOIN month_names AS mn
			ON mi.month_str = mn.month_name
			   AND replace(STR(mn.id,2),SPACE(1),'0') = replace(STR(@CURRENTMONTH,2),SPACE(1),'0')


	--SELECT
	--		gp.*
	--	    ,mi.Seq_id
	--	FROM
	--		GlobalParameters AS gp
	--		INNER JOIN ##Month_id AS mi
	--			ON gp.CurrentMonthSTR = mi.month_str


	--    select mi.*, replace(STR(mn.id,2),SPACE(1),'0') from ##Month_id mi
	--			join month_names mn on mi.month_str = mn.month_name
	--			and replace(STR(mn.id,2),SPACE(1),'0') = @CURRENTMONTH

	IF OBJECT_ID('tempdb..##tmpUnpvtPuertoRico') IS NOT NULL
	BEGIN
		DROP TABLE ##tmpUnpvtPuertoRico
	END

	CREATE TABLE ##tmpUnpvtPuertoRico (
		initiative NVARCHAR(500)
	    ,media_type NVARCHAR(500)
	    ,month NVARCHAR(500)
	    ,value NVARCHAR(500)
	    ,month_id INT
	    ,Year INT) 

	INSERT INTO ##tmpUnpvtPuertoRico
	SELECT 
		initiative
	    ,media_type
	    ,month
	    ,value
	    ,mn.id AS month_id
	    ,CASE
			WHEN mn.id >=
					    (
						SELECT 
							CurrentMonth
						FROM 
							##GlobalParamSeq
					    ) THEN
							 (
							  SELECT 
								  CurrentYear
							  FROM 
								  ##GlobalParamSeq
							 )
			WHEN mn.id <
					   (
					    SELECT 
						    CurrentMonth
					    FROM 
						    ##GlobalParamSeq
					   )
				AND mi.Seq_id <
							 (
							  SELECT 
								  Seq_id
							  FROM 
								  ##GlobalParamSeq
							 ) THEN
								   (
								    SELECT 
									    CurrentYear
								    FROM 
									    ##GlobalParamSeq
								   )
			ELSE
				(
				 SELECT 
					 CurrentYear + 1
				 FROM 
					 ##GlobalParamSeq
				)
		END AS Year
	FROM
		(
		 SELECT 
			 initiative
			,media_type
			,sep
			,oct
			,nov
			,dec
			,jan
			,feb
			,mar
			,apr
			,may
			,jun
			,jul
			,aug
		 FROM 
			 #STG_PuertoRico
		 WHERE initiative IS NOT NULL
			--  AND COALESCE(sep,oct,nov,dec,jan,feb,mar,apr,may,jun,jul,aug) IS NOT NULL
			AND COALESCE(sep,oct,nov,dec,jan,feb,mar,apr,may,jun,jul,aug) IS NOT NULL
		) AS P UNPIVOT(value FOR month IN(
		sep
	    ,oct
	    ,nov
	    ,dec
	    ,jan
	    ,feb
	    ,mar
	    ,apr
	    ,may
	    ,jun
	    ,jul
	    ,aug)) AS UNPVT
		INNER JOIN month_names AS mn
			ON mn.month_name = UPPER(UNPVT.month)
		INNER JOIN ##Month_id AS mi
			ON mi.month_str = UNPVT.month
	WHERE mi.Seq_id >=
				    (
					SELECT 
						Seq_id
					FROM 
						##GlobalParamSeq
				    ) 

	MERGE Fact_Outcome AS target
	USING
		 (
		  SELECT 
			  di.id AS Id_Initiative
			 ,mt.id AS Id_media_type
			 ,stg.value
			 ,dd.id_Dim_Date
			 ,10 AS id_type
			 ,
			   (
			    SELECT 
				    id_Dim_Date
			    FROM 
				    dim_date
			    WHERE year = @CURRENTYEAR
					AND month = @CURRENTMONTH
			   ) AS id_time_generated
		  FROM 
			  ##tmpUnpvtPuertoRico AS stg
			  INNER JOIN dim_initiative AS di
				  ON di.initiative_name = stg.initiative
			  INNER JOIN dim_media_type AS mt
				  ON mt.media_type = stg.media_type
			  INNER JOIN dim_wag_initiative_media_type AS wim
				  ON wim.id_initiative = di.id
					AND wim.id_media_type = mt.id
					--AND wim.id_dim_date between @ID_MINDIM_DATE and @ID_DIM_DATE  
					AND wim.id_dim_date = @ID_DIM_DATE  
			  INNER JOIN Dim_Date AS dd
				  ON dd.year = stg.Year
					AND dd.month = stg.month_id
			  INNER JOIN GlobalParameters AS gp
				  ON gp.CurrentYear <= stg.Year
				  AND stg.value <> 0
		 ) AS source
		 ON source.id_initiative = target.id_initiative
		    AND source.id_media_type = target.id_media_type
		    AND source.id_type = target.id_type
		    AND source.id_Dim_Date = target.id_time
		    AND source.id_time_generated = target.id_time_generated
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		id_initiative
	    ,id_media_type
	    ,value
	    ,id_time
	    ,id_type
	    ,id_time_generated)
		 VALUES (
			   source.id_initiative
			  ,source.id_media_type
			  ,source.value
			  ,source.id_dim_date
			  ,source.id_type
			  ,source.id_time_generated) 
		WHEN MATCHED AND target.value != source.value
		 THEN UPDATE SET 
		target.value = source.value
		 OUTPUT 
		$action
	    ,inserted.id_fact_outcome
	    ,source.id_dim_date
	    ,deleted.value
			   INTO @tablepuertorico(
		ACTION
	    ,id_Fact_Outcome
	    ,id_dim_date
	    ,value);

	IF @@ROWCOUNT > 0
	BEGIN
		SET @SUCCESSWITHOUTROWS = 0
	END
		ELSE
	BEGIN
		SET @SUCCESSWITHOUTROWS = 1
	END
	INSERT INTO Fact_Outcome_History
	SELECT 
		ID_fact_outcome
	    ,CASE
			WHEN ACTION = 'UPDATE' THEN value
			WHEN ACTION = 'INSERT' THEN 0
		END AS value
	    ,@ExecutionID
	FROM 
		@tablepuertorico

	IF @SUCCESSWITHOUTROWS = 1
	BEGIN
		EXEC usp_update_execution_log 
			@ExecutionID
		    ,'SuccessNoRowsGenerated'
		    ,'Generate'
		    ,'Process finished successfully all steps.'
	END
		ELSE
	BEGIN
		EXEC usp_update_execution_log 
			@ExecutionID
		    ,'Success'
		    ,'Generate'
		    ,'Process finished successfully all steps.'
	END

END
--******************************************************   END SP usp_Table_Creation *******************************************************************************************/
