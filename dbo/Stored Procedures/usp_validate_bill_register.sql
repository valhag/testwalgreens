--	stored procedure name: usp_validate_bill_register
--	description: usp that validates data about bill register file type
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
----		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018

--	drop PROC [usp_validate_bill_register]

--***************************************************************************** CREATE SP **************************************************************************************************************************************
CREATE PROC dbo.usp_validate_bill_register (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN
	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT

	-- validation to check if there are rows on STG_Bill_Register if not adverity does not load any data and an error is retrieved
	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_Bill_Register
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
							WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = '2' THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',
							UPPER(FILENAME)) - 6,4)
							ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
						END
		    ,@CURRENTMONTH = CASE
							 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != '2' THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',
							 UPPER(FILENAME)) - 6,2)
							 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
						 END
		FROM 
			STG_Bill_Register
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'BILL REGISTER PROCESS NO ROWS'
		SET @Folder = 'BILL REGISTER NO ROWS'
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = MONTH(GETDATE())
			 AND year = YEAR(GETDATE())
	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'BILL REGISTER PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'BILL REGISTER PROCESS NO ROWS'
			 ,GETDATE()) 
	END


	
	INSERT INTO ERRORS
	-- this query validate all the documented error messages, 
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,row_number + 1
	    ,value
	    ,GETDATE()
	FROM
		(
		 SELECT 
			 row_number
			,CONVERT(VARCHAR(2000),ISNULL(msg1,'')) AS msg1
			,CONVERT(VARCHAR(2000),ISNULL(msg2,'')) AS msg2
			,CONVERT(VARCHAR(2000),ISNULL(msg3,'')) AS msg3
			,CONVERT(VARCHAR(2000),ISNULL(msg4,'')) AS msg4
			,CONVERT(VARCHAR(2000),ISNULL(msg5,'')) AS msg5
			,CONVERT(VARCHAR(2000),ISNULL(msg6,'')) AS msg6
			,CONVERT(VARCHAR(2000),ISNULL(msg7,'')) AS msg7
		 FROM
			 (
			  SELECT 
				  stg.row_number  
				  --row_number, dmnotv.media_type,dm.media_type, dw.product, dwnotv.estimate, ditv.initiative_name, dinotv.initiative_name, dwimtv.id,  dwimnotv.id, dm.id, dmnotv.id 
				 ,CASE
					  WHEN dm.media_type IS NULL
						  AND dmnotv.media_type IS NULL THEN ' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; gl_code "' + gl_code +
						  '" is not listed on Master Tracker Match file '
				  END AS msg1
				 ,CASE
					  WHEN ditv.id IS NULL
						  AND dm.id IS NOT NULL THEN ' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; Initiative "' + dw.initiative
						  + '" does not exist on Master Tracker Match file'
				  END AS msg2
				  --,CASE
--					  WHEN dinotv.id IS NULL
--						  AND dmnotv.id IS NOT NULL THEN ' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; Initiative "' + dwnotv.
--						  initiative + '" does not exist on Master Tracker Match file'
--				  END AS msg3

				 ,CASE
					  WHEN dwnotv.estimate IS NULL
						  AND dm.media_type IS NULL THEN 'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; Estimate "' + stg.estimate
						  + '" does not have a matching estimate on writer match file. This line uses Estimate to lookup Initiative because its Media Type is not TV'
				  END AS msg3
				 ,CASE
					  WHEN dw.product IS NULL
						  AND dm.media_type IS NOT NULL THEN 'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; product "' + stg.
						  product +
						  '" does not have a matching Product on writer match file. This entry uses Product to look up initiative because its Media Type is TV'
				  END AS msg4
				 ,CASE
					  WHEN dwnotv.estimate IS NULL
						  AND dmnotv.media_type IS NOT NULL THEN 'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) +
						  '; the combination of Initiative "' + ditv.initiative_name + '" (as matched from the Estimate Name Match File) and Media Type "' + dm.
						  media_type +
						  '" doesn''t exist on the Master Tracker Match File. If this combination  is correct, the Master Tracker Match File should be updated'
				  END AS msg5
				 ,CASE
					  WHEN dwimtv.id IS NULL
						  AND dm.media_type IS NOT NULL THEN 'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) +
						  '; the combination of Initiative "' + ditv.initiative_name + '" (as matched from the Estimate Name Match File) and Media Type "' + dm.
						  media_type +
						  '" doesn''t exist on the Master Tracker Match File. If this combination  is correct, the Master Tracker Match File should be updated'
				  END AS msg6
				 ,CASE
					  WHEN dwimnotv.id IS NULL
						  AND dmnotv.media_type IS NOT NULL THEN ' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; initiative "' +
						  dinotv.initiative_name + '" and media type ' + dmnotv.media_type + ' do not exist on master tracker match file '
				  END AS msg7
			  FROM 
				  STG_Bill_Register AS stg
				  LEFT JOIN dim_writer_match AS dw
					  ON dw.product = stg.product
						AND input_file = 'Bill Register'
						AND id_dim_date = @ID_DATE
				  LEFT JOIN dim_writer_match AS dwnotv
					  ON dwnotv.estimate = stg.estimate
						AND dwnotv.input_file = 'Bill Register'
						AND dwnotv.id_dim_date = @ID_DATE
				  LEFT JOIN dim_media_type AS dm
					  ON stg.gl_code = dm.media_lawson
						AND dm.media_type = 'TV'
				  LEFT JOIN dim_media_type AS dmnotv
					  ON stg.gl_code = dmnotv.media_lawson
						AND dmnotv.media_type != 'TV'
				  LEFT JOIN dim_initiative AS ditv
					  ON ditv.initiative_name = dw.initiative
				  LEFT JOIN dim_initiative AS dinotv
					  ON dinotv.initiative_name = dwnotv.initiative
				  LEFT JOIN dim_wag_initiative_media_type AS dwimtv
					  ON dwimtv.id_initiative = ditv.id
						AND dwimtv.id_media_type = dm.id
						AND dwimtv.id_dim_date = @ID_DATE
				  LEFT JOIN dim_wag_initiative_media_type AS dwimnotv
					  ON dwimnotv.id_initiative = dinotv.id
						AND dwimnotv.id_media_type = dmnotv.id
						AND dwimnotv.id_dim_date = @ID_DATE
			 ) AS x
		) AS y UNPIVOT(value FOR msg IN(
		msg1
	    ,msg2
	    ,msg3
	    ,msg4
	    ,msg5
	    ,MSG6
	    ,MSG7)) x
	WHERE value != ''
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,wa.row_number + 1
	    ,ISNULL(CASE
				  WHEN LEN(wa.gl_code) < 6 THEN ' Lawson Code Part 2; Lawson Code part 2: "' + wa.gl_code +
				  '" does not have at least 6 characters'
			  END,'') AS error_len
	    ,GETDATE()
	FROM 
		dbo.STG_Bill_Register AS wa
	WHERE LEN(wa.gl_code) < 6
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; Estimate "' + nw.estimate + '" and Product "' + nw.product + '"' +
	    'does not match with a existing entry under the Spot Radio Writer section of the Estimate Name Match File. It does match with an entry in the "'
	    + wdm.input_file + '" section. Please add an entry to the Spot Radio Writer section for this Estimate name.'
	    ,GETDATE()
	FROM 
		dbo.STG_Bill_Register AS nw
		JOIN dbo.dim_writer_match AS wdm
			ON nw.estimate = wdm.estimate
			   AND wdm.input_file != 'Bill Register'
		JOIN dim_media_type AS dm
			ON dm.media_lawson = RIGHT(nw.gl_code,6)
			   AND dm.media_type != 'TV'
	WHERE nw.row_number NOT IN
						  (
						   SELECT 
							   srw.row_number
						   FROM 
							   STG_Bill_Register AS srw
							   JOIN dbo.dim_writer_match AS wdm
								   ON srw.estimate = wdm.estimate
									 AND wdm.input_file = 'Bill Register'
						  ) 
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; Estimate "' + nw.estimate + '" and Product "' + nw.product + '"' +
	    'does not match with a existing entry under the Spot Radio Writer section of the Estimate Name Match File. It does match with an entry in the "'
	    + wdm.input_file + '" section. Please add an entry to the Spot Radio Writer section for this Estimate name.'
	    ,GETDATE()
	FROM 
		dbo.STG_Bill_Register AS nw
		JOIN dbo.dim_writer_match AS wdm
			ON nw.product = wdm.product
			   AND wdm.input_file != 'Bill Register'
		JOIN dim_media_type AS dm
			ON dm.media_lawson = RIGHT(nw.gl_code,6)
			   AND dm.media_type = 'TV'
	WHERE nw.row_number NOT IN
						  (
						   SELECT 
							   srw.row_number
						   FROM 
							   STG_Bill_Register AS srw
							   JOIN dbo.dim_writer_match AS wdm
								   ON srw.product = wdm.product
									 AND wdm.input_file = 'Bill Register'
						  ) 



	--*********************************************************************** VALIDATING ERRORS *************************************************************************************************************************************  

	IF EXISTS
			(
			 SELECT 
				 *
			 FROM 
				 Errors
			 WHERE ExecutionID = @ExecutionID
			) 
	BEGIN
		EXEC usp_update_execution_log 
			@ExecutionID
		    ,'Failed'
		    ,'Validation'
		    ,'Process failed on validation step.'
		SET @Result = 0
		RETURN
	END
		ELSE
	BEGIN
		SET @Result = 1
		RETURN
	END
		--********************************************************************************************************************************************************************************************************************************/

END

