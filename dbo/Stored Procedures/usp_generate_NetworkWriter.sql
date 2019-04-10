--	stored procedure name: usp_generate_NetworkWriter
--	description: usp that generates (insert/update) data of fact_outcome for NETWORK WRITER file type
--	parameters: @executionID just to report success on validation/generation
--	author: HVA
--	Date Creation: 20/11/2018
--	Date Modification: 01/23/2019 change stg for dim
--	Date Modification: 24/01/2019 include id_time_generated
--   Date Modification: 28/01/2019 include just valid initiatives-media types 
--   Date Modification: 02/08/2019 if current month writer match data does not exist copy all data from previous month
--   Date Modification: 02/10/2019 add previousdata
--   Date Modification: 02/13/2019 remove previousdata, implement changes to suppor fact_outcome_history_table
--   Date Modification: 02/18/2019 validate initiative media type apply months
--   Date Modification: 02/28/2019 dim_wag_initiative new rows

--	drop PROC usp_generate_NetworkWriter


CREATE PROC dbo.usp_generate_NetworkWriter (
	@ExecutionID BIGINT
    ,@CURRENTYEAR AS INT
    ,@CURRENTMONTH AS INT) 
AS
BEGIN

    DECLARE @ID_DIM_DATE AS INT
    DECLARE @ID_MINDIM_DATE AS INT

    SELECT @ID_MINDIM_DATE = min(id_dim_date) FROM udf_dimdate (@CURRENTMONTH,@CURRENTYEAR) 
    SELECT @ID_DIM_DATE = id_dim_date FROM udf_dimdate (@CURRENTMONTH,@CURRENTYEAR) where month = @CURRENTMONTH and year= @CURRENTYEAR

	DECLARE @SUCCESSWITHOUTROWS AS INT

	
	SELECT 
		@ID_DIM_DATE = id_dim_date
	FROM 
		dim_date
	WHERE month = @CURRENTMONTH
		 AND YEAR = @CURRENTYEAR


	DECLARE @tablenetwork TABLE (
		ACTION VARCHAR(100)
	    ,id_Fact_Outcome INT
	    ,id_dim_date INT
	    ,value MONEY
	    ) 

	MERGE dbo.Fact_Outcome AS TARGET
	USING
		 (
		  SELECT 
			  di.id AS id_initiative
			 ,dmt.id AS id_media_Type
			 ,SUM(CAST(snwr.billable AS MONEY)) AS value
			 ,dd.id_Dim_Date
			 ,5 AS id_type
			 ,@ID_DIM_DATE AS id_time_generated
		  FROM 
			  dbo.STG_NetworkWriter AS snwr
			  INNER JOIN dbo.dim_writer_match AS wdm
				  ON snwr.estimate = wdm.estimate
					AND wdm.input_file LIKE 'Network%'
					AND wdm.id_dim_date = @ID_DIM_DATE
			  INNER JOIN dbo.dim_initiative AS di
				  ON di.initiative_name = wdm.initiative
			  INNER JOIN dbo.dim_media_type AS dmt
				  ON dmt.media_lawson = RIGHT(snwr.gl_code,6)
			  JOIN dim_wag_initiative_media_type AS dwi
				  ON dwi.id_initiative = di.id
					AND dwi.id_media_type = dmt.id
					--AND dwi.id_dim_date between @ID_MINDIM_DATE and @ID_DIM_DATE  
					AND dwi.id_dim_date = @ID_DIM_DATE  
			  INNER JOIN dbo.month_names AS mn
				  ON mn.month_name = LEFT(snwr.month_of_service,3)
			  INNER JOIN dbo.Dim_Date AS dd
				  ON dd.year = CONVERT(INT,'20' + RIGHT(snwr.month_of_service,2))
					AND dd.month = mn.id
					AND LTRIM(RTRIM(STR(dd.year))) + RTRIM(LTRIM(replace(STR(dd.month,2),SPACE(1),'0'))) > LTRIM(RTRIM(STR(@CURRENTYEAR))) +
					RTRIM(LTRIM(replace(STR(@CURRENTMONTH,2),SPACE(1),'0')))
		  GROUP BY 
			  di.id
			 ,dmt.id
			 ,mn.id
			 ,dd.id_Dim_Date
		 ) AS SOURCE
		 ON source.id_initiative = target.id_initiative
		    AND source.id_media_type = target.id_media_type
		    AND source.id_type = target.id_type
		    AND source.id_dim_date = target.id_time
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
			   SOURCE.id_initiative
			  ,SOURCE.id_media_type
			  ,SOURCE.value
			  ,SOURCE.id_dim_date
			  ,SOURCE.id_type
			  ,SOURCE.id_time_generated) 
		WHEN MATCHED and target.value != source.value
		 THEN UPDATE SET 
		target.value = source.value
		 OUTPUT 
		$action
	    ,inserted.id_fact_outcome
	    ,source.id_dim_date
	    ,deleted.value
			   INTO @tablenetwork(
		ACTION
	    ,id_Fact_Outcome
	    ,id_dim_date
	    ,value
	    );

	IF @@ROWCOUNT > 0
	BEGIN
		SET @SUCCESSWITHOUTROWS = 0
	END
		ELSE
	BEGIN
		SET @SUCCESSWITHOUTROWS = 1
	END


	-- code to save previous values in case we need to restore them
	INSERT INTO Fact_Outcome_History
	SELECT 
		ID_fact_outcome
	    , case when ACTION = 'UPDATE' then value
	    when ACTION = 'INSERT' then 0 END as value
	    ,@ExecutionID
	FROM 
		@tablenetwork

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
	--******************************************************************************************************************************************************************************/

END
--******************************************************   END SP usp_Table_Creation *******************************************************************************************/
