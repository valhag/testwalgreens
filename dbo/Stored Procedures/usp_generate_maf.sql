--	stored procedure name: usp_generate_maf
--	description: usp that generates (insert/update) data of fact_outcome for maf file type
--	parameters: @executionID just to report success on validation/generation
--	author: HVA
--	Date Creation: 20/11/2018
--	Date Modification: 16/01/2019 add new current year management
--	Date Modification: 24/01/2019 include id_time_generated
--	Date Modification: 28/01/2019 include just valid initiatives-media types 
--	Date Modification: 01/31/2019 copy a calculated maf into future months inside FY
--	Date Modification: 02/10/2019 maf match current month year
--   Date Modification: 02/10/2019 add previousdata
--   Date Modification: 02/13/2019 remove previousdata, implement changes to suppor fact_outcome_history_table
--   Date Modification: 02/18/2019 validate initiative media type apply months
--   Date Modification: 02/20/2019 change id_time_generated source
--   Date Modification: 03/06/2019 issue 37


--	drop PROC usp_generate_maf

CREATE PROC dbo.usp_generate_maf (
	@ExecutionID BIGINT
    ,@CURRENTYEAR AS INT
    ,@CURRENTMONTH AS INT) 
AS
BEGIN

	DECLARE @SUCCESSWITHOUTROWS AS INT
	DECLARE @CURRENTYEARFOLLOW INT;
	DECLARE @CURRENTYEARPREVIOUS INT

	DECLARE @tablemaf TABLE (
		ACTION VARCHAR(100)
	    ,id_Fact_Outcome INT
	    ,id_dim_date INT
	    ,value MONEY) 

	IF CONVERT(INT,@CURRENTMONTH) >= 9
	BEGIN
		SET @CURRENTYEARFOLLOW = @CURRENTYEAR + 1
		SET @CURRENTYEARPREVIOUS = @CURRENTYEAR

	END
		ELSE
	BEGIN
		SET @CURRENTYEARFOLLOW = @CURRENTYEAR
		SET @CURRENTYEARPREVIOUS = @CURRENTYEAR - 1
	END;

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
		 AND year = @CURRENTYEAR;



	WITH DATECTE(
		id_Dim_Date
	    ,month
	    ,year)
		AS (SELECT 
			    id_Dim_Date
			   ,month
			   ,year
		    FROM 
			    Dim_Date
		    WHERE year IN (
					   @CURRENTYEAR
					  ,@CURRENTYEAR + 1
					  ,@CURRENTYEAR - 1)
				AND month >= 9
				AND year = @CURRENTYEARPREVIOUS
		    UNION
		    SELECT 
			    id_Dim_Date
			   ,month
			   ,year
		    FROM 
			    Dim_Date
		    WHERE year IN (
					   @CURRENTYEAR
					  ,@CURRENTYEAR + 1
					  ,@CURRENTYEAR - 1)
				AND month BETWEEN 1 AND 8
				AND year = @CURRENTYEARFOLLOW)

		MERGE Fact_Outcome AS target
		USING
			 (
			  SELECT 
				  di.id AS id_initiative
				 ,dt.id AS id_mediatype
				 ,SUM(CONVERT(MONEY,m.annual_maf_)) AS value
				 ,dcte.id_dim_date AS id_dim_date
				 ,1 AS id_type
				 ,@ID_DIM_DATE AS id_time_generated
			  FROM 
				  STG_MAF AS m
				  JOIN dim_maf_match AS mm
					  ON mm.maf_initiative = m.initiative
						AND mm.id_dim_date = @ID_DIM_DATE
				  JOIN dim_initiative AS di
					  ON di.initiative_name = mm.master_tracker_initiative
				  JOIN dim_wag_forecast_initiative AS dw
					  ON dw.id = di.id_wag_forecast_initiative
				  JOIN dim_media_type AS dt
					  ON dt.media_type = m.media_type
						AND dt.media_lawson = m.media_lawson
				  JOIN dim_wag_initiative_media_type AS dwm
					  ON dwm.id_initiative = di.id
						AND dwm.id_media_type = dt.id
						--AND dwm.ID_dim_date between @ID_MINDIM_DATE and @ID_DIM_DATE  
						AND dwm.ID_dim_date = @ID_DIM_DATE  
				  JOIN DATECTE AS dcte
					  ON dcte.id_dim_date = @ID_DIM_DATE
			  WHERE client_code = 'WAG'
				   AND di.initiative_name IS NOT NULL
				   AND dt.media_type IS NOT NULL
			  GROUP BY 
				  di.id
				 ,dt.id
				 ,dcte.id_dim_date
			  HAVING SUM(CONVERT(MONEY,m.annual_maf_)) > 0
			 ) AS source
			 ON source.id_initiative = target.id_initiative
			    AND source.id_mediatype = target.id_media_type
			    AND source.id_type = target.id_type
			    AND source.id_dim_date = target.id_time
			    --AND source.id_time_generated = target.id_time_generated
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
				  ,source.id_mediatype
				  ,source.value
				  ,source.id_dim_date
				  ,source.id_type
				  ,source.id_time_generated) 
			WHEN MATCHED AND target.value != source.value
			 THEN UPDATE SET 
			target.Value = source.Value
			 OUTPUT 
			$action
		    ,inserted.id_fact_outcome
		    ,source.id_dim_date
		    ,deleted.value
				   INTO @tablemaf(
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
		@tablemaf

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
