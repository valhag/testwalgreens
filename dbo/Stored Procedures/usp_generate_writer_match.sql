-- drop proc usp_generate_writer_match


-- 01/30/2019 add validation to avoid blanks rows
-- 01/31/2019 add validation to remove product on validation of product field
-- 02/06/2019 does not allow duplicated estimates
-- 02/08/2019 if current month writer match data does not exist copy all data from previous month
-- 02/14/2019 tv writer allow empty estimates
-- 02/19/2019 history
-- 03/11/2019 history 2


-- DROP PROC usp_generate_writer_match 

CREATE PROC usp_generate_writer_match (
	@ExecutionID BIGINT
    ,@CURRENTYEAR INT
    ,@CURRENTMONTH INT) 
AS
BEGIN


	/*DECLARE @tablewritermatch TABLE (
		ACTION VARCHAR(100)
	    ,id_dim_writer_match BIGINT
	    ,initiative VARCHAR(100)) */


	DECLARE @ID_DIM_DATE AS INT

	SELECT 
		@ID_DIM_DATE = id_dim_date
	FROM 
		dim_date
	WHERE month = @CURRENTMONTH
		 AND YEAR = @CURRENTYEAR

	-- following statement fills dim_writer_match if there is no current month rows, based on previous month rows
	/*IF NOT EXISTS
			    (
				SELECT TOP 1 
					*
				FROM 
					dim_writer_match
				WHERE id_dim_date = @ID_DIM_DATE
			    ) 
	BEGIN
		INSERT INTO dim_writer_match(
			estimate
		    ,initiative
		    ,input_file
		    ,product
		    ,id_dim_date
		    ,executionid)
		SELECT 
			estimate
		    ,initiative
		    ,input_file
		    ,product
		    ,@ID_DIM_DATE
		    ,@ExecutionID
		FROM 
			dim_writer_match
		WHERE id_dim_date = @ID_DIM_DATE - 1

		INSERT INTO dim_writer_match_history(
			id_dim_writer_match
		    ,previousinitiative
		    ,Executionid)
		SELECT 
			id_dim_writer_match
		    ,''
		    ,@ExecutionID
		FROM 
			dim_writer_match
		WHERE id_dim_date = @ID_DIM_DATE
	END*/


	INSERT INTO dim_writer_match_history
	SELECT 
		d.estimate
	   ,d.initiative
	   ,d.input_file
	   ,d.product
	   ,d.id_dim_date
	   ,@executionid as executionid
	   , x.executionid as executionidprevious
	FROM 
		dim_writer_match AS d
		JOIN
			(
			 SELECT 
				 d.*
			 FROM 
				 dim_writer_match AS d
			 WHERE d.id_dim_date = @ID_DIM_DATE
				  AND NOT EXISTS
							  (
							   SELECT 
								   1
							   FROM 
								   STG_writerdigital_match AS stg
							   WHERE		  stg.estimate	= d.estimate
								    AND	  stg.input_file	= d.input_file
								    AND	  stg.initiative	= d.initiative
								    AND	  stg.product	= d.product
							  )
			) AS x
			ON d.estimate = x.estimate
			   AND d.input_file = x.input_file
			   AND d.initiative = x.initiative
			   AND d.product = x.product
			   AND x.executionid = d.executionid
	WHERE d.id_dim_date = x.id_dim_date


	-- remove rows not in current execution
	DELETE dim_writer_match
	FROM dim_writer_match dw1
	WHERE 
		NOT EXISTS
				 (
				  SELECT 
					  1
				  FROM 
					  STG_writerdigital_match AS dw
				  WHERE dw1.estimate = dw.estimate
					   AND dw1.initiative = dw.initiative
					   AND dw1.input_file = dw.input_file
					   AND dw1.product = dw.product
				 )
		AND dw1.id_dim_date = @ID_DIM_DATE

	MERGE dim_writer_match AS target
	USING
		 (
		  SELECT 
			  ISNULL(estimate,'') AS estimate
			 ,ISNULL(initiative,'') AS initiative
			 ,ISNULL(input_file,'') AS input_file
			 ,ISNULL(product,'') AS product
			 ,@ID_DIM_DATE AS id_dim_date
			 ,@executionid as executionid
		  FROM 
			  STG_writerdigital_match AS m
		 --where estimate != '' and initiative != '' and input_file != '' --and product != ''
		 ) AS source
	ON source.estimate = target.estimate
	   AND source.id_dim_date = target.id_dim_date
	   AND source.input_file = target.input_file
	   AND source.product = target.product
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		estimate
	    ,initiative
	    ,input_file
	    ,product
	    ,id_dim_date
	    ,executionid)
		 VALUES (
			   source.estimate
			  ,source.initiative
			  ,source.input_file
			  ,source.product
			  ,source.id_dim_date
			  ,source.executionid) 
		WHEN MATCHED
		 THEN UPDATE SET 
		target.initiative = source.initiative;
	/*OUTPUT 
		$action
	    ,inserted.id_dim_writer_match
	    ,deleted.initiative
		  INTO @tablewritermatch(
		ACTION
	    ,id_dim_writer_match
	    ,initiative);*/


	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'
	--******************************************************************************************************************************************************************************/
END
