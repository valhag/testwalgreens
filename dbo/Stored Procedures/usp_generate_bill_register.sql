--	stored procedure name: usp_generate_bill_register
--	description: usp that generates data into fact_outcome table about bill register file type
--	parameters: @ExecutionID unique identifier by execution, sent by validation process in order to save succesfull execution.
--	author: HVA
--	Date Creation: 11/25/2018 
--	drop PROC [usp_generate_bill_register]


CREATE PROC dbo.usp_generate_bill_register (
	@ExecutionID BIGINT
    ,@CURRENTYEAR AS INT
    ,@CURRENTMONTH AS INT) 
AS
BEGIN

	DECLARE @SUCCESSWITHOUTROWS AS INT
	DECLARE @YEARINI INT
	DECLARE @YEAREND INT

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


	-- #Dim_DatePreviousYear contains Previous Year valid months (for instance if current month is november of 2018 #Dim_DatePreviousYear will contain September 2017 to August 2018 months
	IF OBJECT_ID('tempdb..#Dim_DatePreviousYear') IS NOT NULL
	BEGIN
		DROP TABLE #Dim_DatePreviousYear;
	END;

	-- intermediate table to calculate previous fy bill register rows
	IF OBJECT_ID('tempdb..#temp2') IS NOT NULL
	BEGIN
		DROP TABLE #temp2;
	END;

	-- table for history purpouses
	DECLARE @tablebillregister TABLE (
		ACTION VARCHAR(100)
	    ,id_Fact_Outcome INT
	    ,id_dim_date INT
	    ,value MONEY) 

	-- insert current fiscal year rows 
	MERGE Fact_Outcome AS target
	USING
		 (
		  SELECT 
			  di.id AS id_initiative
			 ,tmp.id_media_type
			 ,SUM(CONVERT(MONEY,tmp.actual_amnt)) AS value
			 ,@ID_DIM_DATE AS id_time
			 ,12 AS id_type
			 ,@ID_DIM_DATE AS id_time_generated
		  --,tmp.initiative
		  FROM
			  (
			  -- this query will retrieve staging table rows just for TV
			  SELECT 
				  id_media_type
				 ,stg.actual_amnt
				 ,dw.initiative
			  FROM
				  (
				   SELECT 
					   product
					  ,estimate
					  ,dm.id AS id_media_type
					  ,dm.media_type
					  ,row_number
					  ,CASE
						   WHEN dm.media_type = 'TV' THEN product
						   ELSE estimate
					   END AS estimatestg
					  ,mos
					  ,actual_amnt
					  ,filename
				   FROM 
					   STG_Bill_Register AS stg
					   JOIN dim_media_type AS dm
						   ON dm.media_lawson = RIGHT(stg.gl_code,6)
				   WHERE media_type = 'TV'
				  ) AS stg
				  JOIN dim_media_type AS dm
					  ON dm.id = stg.id_media_type
				  JOIN dim_writer_match AS dw
					  ON dw.product = stg.estimatestg
						AND dw.input_file = 'Bill Register'
						AND dw.id_dim_date = @ID_DIM_DATE
			  UNION
			  -- this query will retrieve staging table No TV rows 
			  SELECT 
				  id_media_type
				 ,stg.actual_amnt
				 ,dw.initiative
			  FROM
				  (
				   SELECT 
					   product
					  ,estimate
					  ,dm.id AS id_media_type
					  ,dm.media_type
					  ,row_number
					  ,CASE
						   WHEN dm.media_type = 'TV' THEN product
						   ELSE estimate
					   END AS estimatestg
					  ,mos
					  ,actual_amnt
					  ,filename
				   FROM 
					   STG_Bill_Register AS stg
					   JOIN dim_media_type AS dm
						   ON dm.media_lawson = RIGHT(stg.gl_code,6)
				   WHERE media_type != 'TV'
				  ) AS stg
				  JOIN dim_media_type AS dm
					  ON dm.id = stg.id_media_type
				  JOIN dim_writer_match AS dw
					  ON dw.estimate = stg.estimatestg
						AND dw.input_file = 'Bill Register'
						AND dw.id_dim_date = @ID_DIM_DATE
			  ) AS tmp
			  JOIN dim_initiative AS di
				  ON di.initiative_name = tmp.initiative
			  JOIN dim_wag_initiative_media_type AS dwi
				  ON dwi.id_initiative = di.id
					AND dwi.id_media_type = tmp.id_media_type
					AND dwi.id_dim_date = @ID_DIM_DATE
		  GROUP BY 
			  di.id
			 ,tmp.id_media_type
		 ) AS source
			  ON source.id_initiative = target.id_initiative
				AND source.id_media_type = target.id_media_type
				AND source.id_time = target.id_time
				AND source.id_type = target.id_type
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
			  ,source.id_time
			  ,source.id_type
			  ,source.id_time_generated) 
		WHEN MATCHED AND target.value != source.value
		 THEN UPDATE SET 
		target.Value = source.Value
			  OUTPUT 
		$action
	    ,inserted.id_fact_outcome
	    ,source.id_time
	    ,deleted.value
				    INTO @tablebillregister(
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


	


	-- save previous fiscal year bill register rows

	IF @CURRENTMONTH >= 9
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 1
		SET @YEAREND = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 2
		SET @YEAREND = @CURRENTYEAR - 1
	END;

	WITH DATECTE1(
		id_Dim_Date
	    ,month
	    ,year)
		AS (SELECT 
			    id_Dim_Date
			   ,month
			   ,YEAR
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEARINI)
				AND month >= 9
				AND year = @YEARINI
		    UNION
		    SELECT 
			    id_Dim_Date
			   ,month
			   ,YEAR
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEAREND)
				AND month BETWEEN 1 AND 8
				AND year = @YEAREND)
		SELECT 
			id_Dim_Date
		    ,month
		    ,YEAR
		INTO 
			#Dim_DatePreviousYear
		FROM 
			DATECTE1 AS d;


	DECLARE @FY AS INT
	SELECT 
		@FY = MAX(year)
	FROM 
		#Dim_DatePreviousYear
	SELECT 
		id_media_type
	    ,stg.actual_amnt
	    ,dw.initiative
	    ,stg.id_dim_date
	INTO 
		#temp2
	FROM
		(
		 SELECT 
			 product
			,estimate
			,dm.id AS id_media_type
			,dm.media_type
			,row_number
			,CASE
				 WHEN dm.media_type = 'TV' THEN product
				 ELSE estimate
			 END AS estimatestg
			,mos
			,actual_amnt
			,filename
			,stg.id_dim_date
		 FROM
			 (
			  SELECT 
				  *
			  FROM 
				  STG_Bill_Register AS stg
				  JOIN month_names AS m
					  ON LEFT(mos,3) = m.month_name
				  JOIN #Dim_DatePreviousYear AS d
					  ON d.month = m.id
						AND d.year = '20' + RIGHT(MOS,2)
			 ) AS stg
			 JOIN dim_media_type AS dm
				 ON dm.media_lawson = RIGHT(stg.gl_code,6)
		 WHERE media_type = 'TV'
		) AS stg
		JOIN dim_media_type AS dm
			ON dm.id = stg.id_media_type
		JOIN dim_writer_match AS dw
			ON dw.product = stg.estimatestg
			   AND dw.input_file = 'Bill Register'
			   AND dw.id_dim_date = @ID_DIM_DATE
	UNION
	SELECT 
		id_media_type
	    ,stg.actual_amnt
	    ,dw.initiative
	    ,stg.id_dim_date
	FROM
		(
		 SELECT 
			 product
			,estimate
			,dm.id AS id_media_type
			,dm.media_type
			,row_number
			,CASE
				 WHEN dm.media_type = 'TV' THEN product
				 ELSE estimate
			 END AS estimatestg
			,mos
			,actual_amnt
			,filename
			,stg.id_dim_date
		 FROM
			 (
			  SELECT 
				  *
			  FROM 
				  STG_Bill_Register AS stg
				  JOIN month_names AS m
					  ON LEFT(mos,3) = m.month_name
				  JOIN #Dim_DatePreviousYear AS d
					  ON d.month = m.id
						AND d.year = '20' + RIGHT(MOS,2)
			 ) AS stg
			 JOIN dim_media_type AS dm
				 ON dm.media_lawson = RIGHT(stg.gl_code,6)
		 WHERE media_type != 'TV'
		) AS stg
		JOIN dim_media_type AS dm
			ON dm.id = stg.id_media_type
		JOIN dim_writer_match AS dw
			ON dw.estimate = stg.estimatestg
			   AND dw.input_file = 'Bill Register'
			   AND dw.id_dim_date = @ID_DIM_DATE



	-- insert media type - initiative combination for previous fiscal year
	MERGE dim_wag_initiative_media_type AS target
	USING
		 (
		  SELECT 
			  di.id AS id_initiative
			 ,temp.id_media_type
			 ,temp.id_dim_date
			 ,1 AS executionid
			 ,@fy AS fiscalyear
		  FROM 
			  #temp2 AS temp
			  JOIN dim_initiative AS di
				  ON di.initiative_name = temp.initiative
			  JOIN dim_wag_initiative_media_type AS dwi
				  ON dwi.id_initiative = di.id
					AND dwi.id_media_type = temp.id_media_type
					AND dwi.id_dim_date = @ID_DIM_DATE
		  GROUP BY 
			  di.id
			 ,temp.id_media_type
			 ,temp.id_dim_date
		 ) AS source
		 ON source.id_media_type = target.id_media_type
		    AND source.id_initiative = target.id_initiative
		    AND source.id_dim_date = target.id_dim_date
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		id_media_type
	    ,id_initiative
	    ,id_dim_date
	    ,executionid
	    ,fiscalyear)
		 VALUES (
			   source.id_media_type
			  ,source.id_initiative
			  ,source.id_dim_date
			  ,1
			  ,source.fiscalyear);


	-- insert bill register rows for previous fiscal year
	MERGE Fact_Outcome AS target
	USING
		 (
		  SELECT 
			  di.id AS id_initiative
			 ,temp.id_media_type
			 ,SUM(CONVERT(MONEY,temp.actual_amnt)) AS value
			 ,temp.id_dim_date AS id_time
			 ,12 AS id_type
			 ,@ID_DIM_DATE AS id_time_generated
		  FROM
			  (
			   SELECT 
				   *
			   FROM 
				   #temp2
			  ) AS temp
			  JOIN dim_initiative AS di
				  ON di.initiative_name = temp.initiative
			  JOIN dim_wag_initiative_media_type AS dwi
				  ON dwi.id_initiative = di.id
					AND dwi.id_media_type = temp.id_media_type
					AND dwi.id_dim_date = @ID_DIM_DATE
		  GROUP BY 
			  di.id
			 ,temp.id_media_type
			 ,temp.id_dim_date
		 ) AS source
		 ON source.id_initiative = target.id_initiative
		    AND source.id_media_type = target.id_media_type
		    AND source.id_time = target.id_time
		    AND source.id_type = target.id_type
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
			  ,source.id_time
			  ,source.id_type
			  ,source.id_time_generated) 
		WHEN MATCHED AND target.value != source.value
		 THEN UPDATE SET 
		target.Value = source.Value
		 OUTPUT 
		$action
	    ,inserted.id_fact_outcome
	    ,source.id_time
	    ,deleted.value
			   INTO @tablebillregister(
		ACTION
	    ,id_Fact_Outcome
	    ,id_dim_date
	    ,value);


    -- Fact_Outcome_History will save previous values 
	INSERT INTO Fact_Outcome_History
	SELECT 
		ID_fact_outcome
	    ,CASE
			WHEN ACTION = 'UPDATE' THEN value
			WHEN ACTION = 'INSERT' THEN 0
		END AS value
	    ,@ExecutionID
	FROM 
		@tablebillregister



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
	--******************************************************************************************************************************************************************************/

END
--******************************************************   END SP usp_Table_Creation *******************************************************************************************/

