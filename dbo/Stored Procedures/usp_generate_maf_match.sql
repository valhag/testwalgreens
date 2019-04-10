--	stored procedure name: usp_generate_maf_match
--	description: usp that generates (insert/update) data of dim_maf_match (to find matches between maf initiatives and master tracker initiatives)
--	author: HVA
--	Date Creation: 20/11/2018
--	Date modification: 02/10/2019 if current month MAF match data does not exist copy all data from previous month
--	Date modification: 02/15/2019 move maf match data from previous month when there is data on that month
--	Date modification: 02/18/2019 add execution id to remove previous values 
--	Date modification: 02/28/2019 delete rows when another file comes


--	drop PROC usp_generate_maf_match

CREATE PROC usp_generate_maf_match (
	@ExecutionID BIGINT
    ,@CURRENTMONTH INT
    ,@CURRENTYEAR INT) 
AS
BEGIN

	DECLARE @ID_DIM_DATE AS INT

	SELECT 
		@ID_DIM_DATE = id_dim_date
	FROM 
		dim_date
	WHERE month = @CURRENTMONTH
		 AND YEAR = @CURRENTYEAR


	-- following statement fills dim_maf_match if there is no current month rows, based on previous month rows, if there is no rows on FY process wont take previous month rows
	--	IF NOT EXISTS
--			    (
--				SELECT TOP 1
--					*
--				FROM
--					dim_maf_match
--				WHERE id_dim_date = @ID_DIM_DATE
--			    )
--	BEGIN
--		IF NOT EXISTS
--				    (
--					SELECT TOP 1
--						*
--					FROM
--						dim_maf_match
--					WHERE id_dim_date IN
--									 (
--									  SELECT
--										  id_dim_date
--									  FROM
--										  DBO.udf_dimdate (@CURRENTMONTH,@CURRENTYEAR)
--									 )
--				    )
--		BEGIN

	--			INSERT INTO dim_maf_match(
--				maf_initiative
--			    ,master_tracker_initiative
--			    ,id_dim_date)
--			SELECT
--				maf_initiative
--			    ,master_tracker_initiative
--			    ,id_dim_date
--			FROM
--				dim_maf_match
--			WHERE id_dim_date = @ID_DIM_DATE - 1
--		END
--	END

	DELETE FROM dim_maf_match
	FROM dim_maf_match d
		JOIN
			(
			 SELECT 
				 d.*
			 FROM 
				 dim_maf_match AS d
			 WHERE d.id_dim_date = @ID_DIM_DATE
				  AND NOT EXISTS
							  (
							   SELECT 
								   1
							   FROM 
								   STG_maf_match AS stg
							   WHERE stg.maf_initiative = d.maf_initiative
								    AND stg.master_tracker_initiative = d.master_tracker_initiative
							  )
			) AS x
			ON d.maf_initiative = x.maf_initiative
			   AND d.master_tracker_initiative = x.master_tracker_initiative


	IF NOT EXISTS
			    (
				SELECT TOP 1 
					*
				FROM 
					dim_maf_match
				WHERE id_dim_date = @ID_DIM_DATE
			    ) 
	BEGIN
		INSERT INTO dim_maf_match(
			maf_initiative
		    ,master_tracker_initiative
		    ,id_dim_date
		    ,executionid)
		SELECT 
			maf_initiative
		    ,master_tracker_initiative
		    ,@ID_DIM_DATE
		    ,@ExecutionID
		FROM 
			dim_maf_match
		WHERE id_dim_date = @ID_DIM_DATE - 1
	END

	MERGE dim_maf_match AS target
	USING
		 (
		  SELECT 
			  *
			 ,@ID_DIM_DATE AS id_dim_date
			 ,@ExecutionId AS executionid
		  FROM 
			  STG_MAF_match AS m
		 ) AS source
	ON source.maf_initiative = target.maf_initiative
	   AND source.id_dim_date = target.id_dim_date
	--AND source.master_tracker_initiative = target.master_tracker_initiative
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		maf_initiative
	    ,master_tracker_initiative
	    ,id_dim_date
	    ,executionid)
		 VALUES (
			   source.maf_initiative
			  ,source.master_tracker_initiative
			  ,@ID_DIM_DATE
			  ,source.executionid) 
		WHEN MATCHED
		 THEN UPDATE SET 
		target.master_tracker_initiative = source.master_tracker_initiative;
	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'
END	
