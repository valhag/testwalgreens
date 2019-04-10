--	stored procedure name: usp_generate_external_wag
--	description: usp that generates (insert/update) data of fact_outcome for external_wag file type
--	parameters: @executionID just to report success on validation/generation
--	author: HVA
--	Date Creation: 20/11/2018
--	drop PROC usp_generate_external_wag

CREATE PROC dbo.usp_generate_external_wag (
	@ExecutionID BIGINT
    ,@CURRENTYEAR INT
    ,@CURRENTMONTH VARCHAR(2)) 
AS
BEGIN

	DECLARE @SUCCESSWITHOUTROWS AS INT

	--Following code creates a #Dim_Date table which contains all fiscal year rows about currentyear and currentmonth parameters, if september is current month all the generated rows will be saves on sept-aug period previous FY
	DECLARE @CURRENTYEARFOLLOW INT;
	DECLARE @CURRENTYEARPREVIOUS INT


	DECLARE @ID_DIM_DATEE AS INT
	DECLARE @ID_MINDIM_DATE AS INT

	SELECT 
		@ID_MINDIM_DATE = MIN(id_dim_date)
	FROM 
		udf_dimdate (@CURRENTMONTH,@CURRENTYEAR) 
	SELECT 
		@ID_DIM_DATEE = id_dim_date
	FROM 
		udf_dimdate (@CURRENTMONTH,@CURRENTYEAR)
	WHERE month = @CURRENTMONTH
		 AND year = @CURRENTYEAR

    -- @tableexternal variable table just to save previous values of fact_outcome table on history table
	DECLARE @tableexternal TABLE (
		ACTION VARCHAR(100)
	    ,id_Fact_Outcome INT
	    ,id_dim_date INT
	    ,value MONEY) 

     -- @FY is used to save new initiative - media type combinations for external wag media type.
	DECLARE @FY AS INT
	SELECT 
		@FY = MAX(year)
	FROM 
		dbo.udf_dimdate (@CURRENTMONTH,@CURRENTYEAR) 

	IF @CURRENTMONTH = '09'
	BEGIN
		SET @CURRENTYEARFOLLOW = @CURRENTYEAR
		SET @CURRENTYEARPREVIOUS = @CURRENTYEAR - 1
	END
		ELSE
	BEGIN
		IF CONVERT(INT,@CURRENTMONTH) > 9
		BEGIN
			SET @CURRENTYEARFOLLOW = @CURRENTYEAR + 1
			SET @CURRENTYEARPREVIOUS = @CURRENTYEAR

		END
			ELSE
		BEGIN
			SET @CURRENTYEARFOLLOW = @CURRENTYEAR
			SET @CURRENTYEARPREVIOUS = @CURRENTYEAR - 1
		END
	END;

	-- first step is to create external wag initiatives
	INSERT INTO dim_initiative
	SELECT 
		dw.id
	    ,dw.wag_forecast_initiative + ' ExtWag'
	    ,'N'
	FROM 
		STG_External_WAG_Forecast AS stgw
		JOIN dim_wag_forecast_initiative AS dw
			ON stgw.wag_initiative = dw.wag_forecast_initiative
	WHERE NOT EXISTS
				  (
				   SELECT 
					   initiative_name
				   FROM 
					   dim_initiative AS di
				   WHERE di.initiative_name = dw.wag_forecast_initiative + ' ExtWag'
				  ) 



	-- #temp1 will save all the initiatives contained on stg table

	SELECT 
		*
	    ,LEAD(row_number,1,0) OVER(
		ORDER BY 
		row_number) AS next_row_number
	INTO 
		#temp1
	FROM
		(
		 SELECT 
			 row_number
			,wag_initiative
			,dw.wag_forecast_initiative AS initiative--, di.initiative_name
		 FROM 
			 STG_External_WAG_Forecast AS stgw
			 JOIN dim_wag_forecast_initiative AS dw
				 ON stgw.wag_initiative = dw.wag_forecast_initiative
		) AS x


    -- following code arranges the initiative - media type combination to save them on table
	DECLARE @maxrow INT

	SELECT 
		@maxrow = MIN(row_number)
	FROM 
		STG_External_WAG_Forecast
	WHERE row_number >
				    (
					SELECT 
						MAX(row_number)
					FROM 
						#temp1
				    )
		 AND wag_initiative = 'Other'



	UPDATE #temp1
	SET 
		next_row_number = @maxrow
	WHERE 
		ROW_NUMBER =
				   (
				    SELECT 
					    MAX(row_number)
				    FROM 
					    #temp1
				   ) 

	UPDATE #temp1
	SET 
		next_row_number = x.next_row_number
	FROM #temp1 t
		JOIN
			(
			 SELECT 
				 row_number
				,CASE
					 WHEN next_row_number - row_number > 40 THEN ROW_NUMBER + 30
					 ELSE next_row_number
				 END AS next_row_number
			 FROM 
				 #temp1
			) AS x
			ON x.row_number = t.row_number



    -- in case @ID_DIM_DATE = 9 all the stg rows will be saved on previous FY if not on current FY
	DECLARE @ID_DIM_DATE AS INT

	IF @CURRENTMONTH = 9
	BEGIN
		SELECT 
			@ID_DIM_DATE = id_dim_date
		FROM 
			dim_date
		WHERE year = @CURRENTYEAR
			 AND month = @CURRENTMONTH - 1
	END
		ELSE
	BEGIN
		SELECT 
			@ID_DIM_DATE = id_dim_date
		FROM 
			dim_date
		WHERE year = @CURRENTYEAR
			 AND month = @CURRENTMONTH;
	END

	-- insert combinations initiatives auto sum and media types
	MERGE dim_wag_initiative_media_type AS target
	USING
		 (
		  SELECT 
			  dm.id AS id_media_type
			 ,di.id AS id_initiative
			 ,@ID_DIM_DATE AS id_dim_date
			 ,@FY AS fiscalyear
			 ,@executionid AS executionid
		  FROM 
			  #temp1 AS stgw
			  JOIN dim_wag_forecast_initiative AS dw
				  ON dw.wag_forecast_initiative = stgw.wag_initiative
			  JOIN dim_initiative AS di
				  ON di.id_wag_forecast_initiative = dw.id
					AND (CHARINDEX('ExtWag',UPPER(initiative_name)) > 0
						OR CHARINDEX('ExtWag',UPPER(initiative_name)) > 0) 
			  JOIN STG_External_WAG_Forecast AS stg
				  ON stg.wag_initiative != stgw.wag_initiative
			  --	OR stg.initiative IS NULL
			  JOIN dim_media_type AS dm
				  ON dm.media_type = stg.wag_initiative
		  WHERE stg.row_number BETWEEN stgw.row_number AND stgw.next_row_number
		 ) AS source
		 ON source.id_initiative = target.id_initiative
		    AND source.id_media_type = target.id_media_type
		    AND source.fiscalyear = target.fiscalyear
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		id_initiative
	    ,id_media_type
	    ,id_dim_date
	    ,fiscalyear
	    ,executionid)
		 VALUES (
			   source.id_initiative
			  ,source.id_media_type
			  ,@ID_DIM_DATE
			  ,@FY
			  ,@ExecutionID);


	-- insert just media types on his primary initiative
	DELETE FROM dim_wag_initiative_media_type
	FROM dim_wag_initiative_media_type dw1
		JOIN
			(
			 SELECT 
				 id_initiative
				,dw.id_media_type
				,id_dim_date
			 FROM 
				 dim_wag_initiative_media_type AS dw
				 JOIN
					 (
					  SELECT 
						  x.id AS con
						 ,dw.id_media_type
					  FROM 
						  dim_initiative AS di
						  JOIN dim_wag_initiative_media_type AS dw
							  ON dw.id_initiative = di.id
								AND dw.id_dim_date = @ID_DIM_DATE
						  JOIN
							  (
							   SELECT 
								   di1.initiative_name
								  ,di1.id
							   FROM 
								   dim_initiative AS di1
							   WHERE CHARINDEX(' ExtWag',di1.initiative_name) > 0
							  ) AS x
							  ON SUBSTRING(x.initiative_name,0,CHARINDEX(' ExtWag',x.initiative_name)) = di.initiative_name
					 ) AS x
					 ON x.con = dw.id_initiative
					    AND X.id_media_type != DW.id_media_type
			 WHERE dw.id_dim_date = @ID_DIM_DATE
			) AS result
			ON result.id_dim_date = dw1.id_dim_date
			   AND result.id_initiative = dw1.id_initiative
			   AND result.id_media_type = dw1.id_media_type


	-- here starts the process to generate info on fact_table
	-- #temp3 table will contain a representation of excel file without any unused data (for example non existing media types)

	IF OBJECT_ID('tempdb..#temp3') IS NOT NULL
	BEGIN
		DROP TABLE #temp3
	END

	SELECT 
		MAX(t.ROW_NUMBER) + 4 AS row_number
	    ,dm.id AS id_media_type
	    ,di.id AS id_initiative
	    ,ISNULL(MAX(t.sepstring),0) AS sep
	    ,ISNULL(MAX(t.octstring),0) AS oct
	    ,ISNULL(MAX(t.novstring),0) AS nov
	    ,ISNULL(MAX(t.decstring),0) AS dec
	    ,ISNULL(MAX(t.janstring),0) AS jan
	    ,ISNULL(MAX(t.febstring),0) AS feb
	    ,ISNULL(MAX(t.martring),0) AS mar
	    ,ISNULL(MAX(t.aprstring),0) AS apr
	    ,ISNULL(MAX(t.maystring),0) AS may
	    ,ISNULL(MAX(t.junstring),0) AS jun
	    ,ISNULL(MAX(t.julstring),0) AS jul
	    ,ISNULL(MAX(t.augstring),0) AS aug
	INTO 
		#temp3
	FROM
		(
		 SELECT 
			 stge.row_number
			,t.initiative AS ini
			,stge.wag_initiative
			,stge.sepstring
			,stge.octstring
			,stge.novstring
			,stge.decstring
			,stge.janstring
			,stge.febstring
			,stge.martring
			,stge.aprstring
			,stge.maystring
			,stge.junstring
			,stge.julstring
			,stge.augstring
		 FROM 
			 #temp1 AS t
			,STG_External_WAG_Forecast AS stge
		 WHERE stge.row_number BETWEEN t.row_number AND t.next_row_number
			  AND stge.wag_initiative != ''
			  AND stge.wag_initiative NOT LIKE 'Subtotal%'
		) AS t
		JOIN dim_wag_forecast_initiative AS dw
			ON dw.wag_forecast_initiative = t.ini
			   AND t.ini != t.wag_initiative
			   AND t.wag_initiative IS NOT NULL
		JOIN dim_initiative AS di
			ON dw.id = di.id_wag_forecast_initiative
			   AND (CHARINDEX('ExtWag',UPPER(di.initiative_name)) > 0
				   OR CHARINDEX('ExtWag',UPPER(di.initiative_name)) > 0)
			   AND CHARINDEX(dw.wag_forecast_initiative,di.initiative_name) > 0
		JOIN
			(
			 SELECT 
				 MIN(id) AS id
				,MIN(media_lawson) AS media_lawson
				,MIN(media_type) AS media_type
			 FROM 
				 dim_media_type
			 GROUP BY 
				 media_type
			) AS dm
			ON dm.media_type = t.wag_initiative
		JOIN dim_wag_initiative_media_type AS dwi
			ON dwi.id_initiative = di.id
			   AND dwi.id_media_type = dm.id
			   AND dwi.id_dim_date = @ID_DIM_DATEE
	GROUP BY 
		dm.id
	    ,di.id





    -- #Dim_Date temporal table will contain fiscal year month which are going to be updated
	IF OBJECT_ID('tempdb..#Dim_Date') IS NOT NULL
	BEGIN
		DROP TABLE #Dim_Date;
	END;

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
		SELECT 
			*
		INTO 
			#Dim_Date
		FROM 
			DATECTE AS d;

	IF @CURRENTMONTH = '09'
	BEGIN
		  -- previous fiscal year adding/modifying rows
		MERGE Fact_Outcome AS target
		USING
			 (
			  SELECT 
				  id_media_type
				 ,id_initiative
				 ,value
				 ,d.id_Dim_Date
				 ,11 AS id_type
				 ,
				   (
				    SELECT 
					    MAX(id_dim_date)
				    FROM 
					    #Dim_Date
				   ) AS id_time_generated
			  FROM
				  (
				   SELECT 
					   *
				   FROM 
					   #temp3
				  ) AS st2 UNPIVOT(value FOR month IN(
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
				 ,aug)) AS List
				  JOIN month_names AS m
					  ON m.month_name = List.month
				  JOIN #Dim_Date AS d
					  ON d.month = m.id
			  WHERE CONVERT(MONEY,value) <> 0
			 ) AS source
			 ON source.id_initiative = target.id_initiative
			    AND source.id_media_type = target.id_media_type
			    AND source.id_dim_date = target.id_time
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
				   INTO @tableexternal(
			ACTION
		    ,id_Fact_Outcome
		    ,id_dim_date
		    ,value);
	END
		ELSE
	BEGIN
		  -- current fiscal year adding/modifying rows
		MERGE Fact_Outcome AS target
		USING
			 (
			  SELECT 
				  id_media_type
				 ,id_initiative
				 ,value
				 ,d.id_Dim_Date
				 ,11 AS id_type
				 ,@ID_DIM_DATE AS id_time_generated
			  FROM
				  (
				   SELECT 
					   *
				   FROM 
					   #temp3
				  ) AS st2 UNPIVOT(value FOR month IN(
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
				 ,aug)) AS List
				  JOIN month_names AS m
					  ON m.month_name = List.month
				  JOIN #Dim_Date AS d
					  ON d.month = m.id
						AND d.id_Dim_Date < @ID_DIM_DATE
			  WHERE CONVERT(MONEY,value) <> 0
			 ) AS source
			 ON source.id_initiative = target.id_initiative
			    AND source.id_media_type = target.id_media_type
			    AND source.id_dim_date = target.id_time
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
				   INTO @tableexternal(
			ACTION
		    ,id_Fact_Outcome
		    ,id_dim_date
		    ,value);
	END




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
		@tableexternal

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
