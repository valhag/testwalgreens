--	stored procedure name: [usp_generate_programmatic]
--	description: usp that generates (insert/update) data of fact_outcome for PROGRAMMATIC file type
--	author: HVA
--	Date Creation: 20/11/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date Modification: 24/01/2019 include id_time_generated
--	Date Modification: 25/01/2019 make sure @CURRENTMONTH must be compared correclty with single character months.
--   Date Modification: 28/01/2019 include just valid initiatives-media types 
--   Date Modification: 02/06/2019 wrong definition of dim_date to dim_wag_initiative_media_type
--   Date Modification: 02/10/2019 add previousdata
--   Date Modification: 02/13/2019 remove previousdata, implement changes to suppor fact_outcome_history_table
--   Date Modification: 02/18/2019 validate initiative media type apply months
--   Date Modification: 02/28/2019 dim_wag_initiative new rows

--	drop PROC [usp_generate_programmatic]

CREATE PROC dbo.usp_generate_programmatic (
	@ExecutionID BIGINT
    ,@CURRENTYEAR AS INT
    ,@CURRENTMONTH AS INT) 
AS
BEGIN



	DECLARE @SUCCESSWITHOUTROWS AS INT
	DECLARE @tableprogrammatic TABLE (
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
	--INSERT INTO ##GlobalParamSeq
	--	SELECT
	--		GlobalParameters.*
	--	    ,##Month_id.Seq_id
	--	FROM
	--		GlobalParameters
	--		INNER JOIN ##Month_id
	--			ON GlobalParameters.CurrentMonthSTR = ##Month_id.month_str    

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
			   --AND replace(STR(mn.id,2),SPACE(1),'0') = @CURRENTMONTH
			   AND replace(STR(mn.id,2),SPACE(1),'0') = RTRIM(LTRIM(replace(STR(@CURRENTMONTH,2),SPACE(1),'0')))


	IF OBJECT_ID('tempdb..##tmpUnpvtProgrammatic') IS NOT NULL
	BEGIN
		DROP TABLE ##tmpUnpvtProgrammatic
	END
	CREATE TABLE ##tmpUnpvtProgrammatic (
		initiative NVARCHAR(500)
	    ,month NVARCHAR(500)
	    ,value NVARCHAR(500)
	    ,month_id INT
	    ,Year INT) 
	INSERT INTO ##tmpUnpvtProgrammatic
	SELECT 
		initiative
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
			,sepstring
			,octstring
			,novstring
			,decstring
			,janstring
			,febstring
			,marstring
			,aprstring
			,maystring
			,junstring
			,julstring
			,augstring
		 FROM 
			 STG_Programmatic
		 WHERE initiative IS NOT NULL
			  AND COALESCE(sepstring,octstring,novstring,decstring,janstring,febstring,marstring,aprstring,maystring,junstring,julstring,augstring)
			  IS NOT NULL
		) AS P UNPIVOT(value FOR month IN(
		sepstring
	    ,octstring
	    ,novstring
	    ,decstring
	    ,janstring
	    ,febstring
	    ,marstring
	    ,aprstring
	    ,maystring
	    ,junstring
	    ,julstring
	    ,augstring)) AS UNPVT
		INNER JOIN month_names AS mn
			ON mn.month_name collate database_default = LEFT(UPPER(UNPVT.month),3)
		INNER JOIN ##Month_id AS mi
			ON mi.month_column_name = UNPVT.month
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
			  di.id AS id_initiative
			 ,dwim.id_media_type AS id_media_type
			 ,stg.value
			 ,dd.id_Dim_Date
			 ,9 AS id_type
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
			  ##tmpUnpvtProgrammatic AS stg
			  INNER JOIN dim_initiative AS di
				  ON di.initiative_name = stg.initiative
			  INNER JOIN dim_wag_initiative_media_type AS dwim
				  ON dwim.id_initiative = di.id
					AND dwim.id_media_type IN(SELECT 
											 id
										 FROM 
											 dim_media_type
										 WHERE media_type = 'Programmatic')
					--AND dwim.id_dim_date between @ID_MINDIM_DATE and @ID_DIM_DATE  
					AND dwim.id_dim_date = @ID_DIM_DATE  
			  INNER JOIN Dim_Date AS dd
				  ON dd.year = stg.Year
					AND dd.month = stg.month_id
			  INNER JOIN GlobalParameters AS gp
				  ON gp.CurrentYear <= stg.Year
		  WHERE stg.value > '0'
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
			   INTO @tableprogrammatic(
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
		@tableprogrammatic

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
