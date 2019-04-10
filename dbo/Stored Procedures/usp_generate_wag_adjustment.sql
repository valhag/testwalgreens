--	stored procedure name: usp_generate_wag_adjustment
--	description: usp that generates (insert/update) data of fact_outcome for wag_initiativefile type
--	parameters: @executionID just to report success on validation/generation
--	author: HVA
--	Date Creation: 20/11/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date Modification: 24/01/2019 include id_time_generated
--   Date Modification: 28/01/2019 include just valid initiatives-media types 
--   Date Modification: 01/31/2019 wrong sp definition
--   Date Modification: 02/10/2019 add previousdata
--   Date Modification: 02/10/2019 if month = 9 send the data to august
--   Date Modification: 02/13/2019 it is not true "if month = 9 send the data to august"
--   Date Modification: 02/13/2019 remove previousdata, implement changes to suppor fact_outcome_history_table
--   Date Modification: 02/18/2019 validate initiative media type apply months
--   Date Modification: 02/28/2019 dim_wag_initiative new rows

--	drop PROC usp_generate_wag_adjustment


CREATE PROC dbo.usp_generate_wag_adjustment (
	@ExecutionID BIGINT
    ,@CURRENTYEAR AS INT
    ,@CURRENTMONTH AS INT) 
AS
BEGIN


	DECLARE @SUCCESSWITHOUTROWS AS INT

	DECLARE @tablewag TABLE (
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


	MERGE Fact_Outcome AS target
	USING
		 (
		  SELECT 
			  di.id AS id_initiative
			 ,dm.id AS id_media_type
			 ,SUM(CONVERT(MONEY,wag_adjustment)) AS value
			 ,@ID_DIM_DATE AS id_time
			 ,8 AS id_type
			 ,@ID_DIM_DATE AS id_time_generated
		  FROM 
			  dbo.STG_WAG_Adjustment AS wa
			  JOIN dim_initiative AS di
				  ON di.initiative_name = wa.initiative
			  JOIN dim_media_type AS dm
				  ON dm.media_lawson = wa.media_lawson_lawson_code_part_2
			  JOIN dim_wag_initiative_media_type AS dwi
				  ON dwi.id_initiative = di.id
					AND dwi.id_media_type = dm.id
					--AND dwi.id_dim_date BETWEEN @ID_MINDIM_DATE AND @ID_DIM_DATE
					AND dwi.id_dim_date = @ID_DIM_DATE
		  GROUP BY 
			  di.id
			 ,dm.id
		 ) AS SOURCE
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
		target.value = source.value
		 OUTPUT 
		$action
	    ,inserted.id_fact_outcome
	    ,source.id_time
	    ,deleted.value
		 --,inserted.previousvalue
			   INTO @tablewag(
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
		@tablewag
		

	--********************************************** UPDATE SUCCESS EXECUTION LOG *************************************************************************************************

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
