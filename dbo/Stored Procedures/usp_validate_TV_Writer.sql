--	stored procedure name: usp_validate_TV_Writer
--	description: usp that generates data on fact_outcome table TV Writer file type
--		  (where the all the process data are saved)
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 change STG_writerdigital_match to dim_writer_match
--	Date modification: 01/30/2019 add validations about estimate matching between stg and dim_match and input_file
--	Date modification: 02/01/2019 messages update
--	Date modification: 02/13/2019 chnnge estimate to product on stg table
--	Date modification: 02/14/2019 stg product = dim product
--	Date modification: 02/20/2019 allow . on filename
--	Date Modification 03/11/2019 error messages

--	drop PROC [usp_validate_TV_Writer]

CREATE PROC dbo.usp_validate_TV_Writer (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN
	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT
	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_TV_Writer
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
							WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',
							UPPER(FILENAME)) - 6,4)
							ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
						END
		    ,@CURRENTMONTH = CASE
							 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',
							 UPPER(FILENAME)) - 6,2)
							 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
						 END
		FROM 
			STG_TV_Writer
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'TV Writer PROCESS NO ROWS'
		SET @Folder = 'TV Writer PROCESS NO ROWS'
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


	IF @FileName = 'TV Writer PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'TV Writer PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO ERRORS
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,CONVERT(VARCHAR(10),row_number + 1) AS 'Row Number'
	    ,'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; Product "' + product +
	    '" does not exist in the Estimate Name Match File under the TV Writer section.' AS 'Error'
	    ,GETDATE()
	FROM 
		STG_TV_Writer AS tw
	WHERE product NOT IN
					 (
					  SELECT 
						  product
					  FROM 
						  dim_writer_match
						  where id_dim_date = @ID_DATE
					 ) 
	UNION
	--SELECT
--		@ExecutionID
--	    ,@FileName
--	    ,CONVERT(VARCHAR(10),tw.row_number + 1) AS 'Row Number'
--	    ,'On excel row ' + CONVERT(VARCHAR(10),tw.row_number + 1) + '; Initiative ' + wdm.initiative +
--	    '" does not exist on "Master Tracker Match File" ' AS 'Error'
--	    ,GETDATE()
--	FROM
--		STG_TV_Writer AS tw
--		JOIN dim_writer_match AS wdm
--			ON tw.product = wdm.product
--			   AND tw.product = wdm.product
--	WHERE wdm.initiative NOT IN
--						   (
--						    SELECT
--							    initiative_name
--						    FROM
--							    dim_initiative
--						   )
--	UNION

	SELECT 
		@ExecutionID
	    ,@FileName
	    ,CONVERT(VARCHAR(10),match.rownumber + 1) AS 'Row Number'
		--,'On excel row ' + CONVERT(VARCHAR(10),match.rownumber + 1) + '; The combination of Initiative "' + match.initiative + '" & Media Type "' +
		--match.media_type + 'does not exist on the "Master Tracker Match File"' AS 'Error'
	    ,'On excel row ' + CONVERT(VARCHAR(10),match.rownumber + 1) + '; The combination of Initiative "' + match.initiative +
	    '" (as matched from the Estimate Name Match File) and media type "' + match.media_type + '" does not exist on Master Tracker Match File'
	    ,GETDATE()
	FROM
		(
		 SELECT 
			 tw.row_number + 1 AS rownumber
			,wdm.initiative
			,dmt.media_type
		 FROM 
			 STG_TV_Writer AS tw
			 JOIN dim_writer_match AS wdm
				 ON tw.product = wdm.product
				 AND wdm.id_dim_date = @ID_DATE
			 LEFT JOIN dim_initiative AS di
				 ON di.initiative_name = wdm.initiative
			 LEFT JOIN dim_media_type AS dmt
				 ON CASE
					    WHEN UPPER(tw.media) = 'OTHER' THEN 'OOH'
					    ELSE 'TV'
				    END = dmt.media_type
		 WHERE di.id IS NULL
			  OR dmt.id IS NULL
		 GROUP BY 
			 tw.row_number
			,wdm.initiative
			,dmt.media_type
		) AS match
	UNION
	-- validation to verify if estimate fields match between stg and di match tables
	--SELECT
	--		@ExecutionID
	--	    ,@FileName
	--	    ,CONVERT(VARCHAR(10),nw.row_number + 1) AS 'Row Number'
	--	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + ' Product ' + nw.product +
	--	    ' does not have a matching estimate on writer match file '
	--	    ,GETDATE()
	--	FROM
	--		STG_TV_Writer AS nw
	--	WHERE nw.product NOT IN
	--						(
	--						 SELECT
	--							 estimate
	--						 FROM
	--							 dim_writer_match
	--						)
	--	UNION
	-- validation to verify the input file is valid
	--SELECT
--		@ExecutionID
--	    ,@FileName
--	    ,nw.row_number + 1
--	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; product "' + nw.product +
--	    '"  is not assigned to TV Writer input file '
--	    ,GETDATE()
--	FROM
--		(
--		 SELECT
--			 dw.input_file
--			,nw.product
--			,nw.row_number
--		 FROM
--			 STG_TV_Writer AS nw
--			 JOIN dim_writer_match AS dw
--				 ON nw.product = dw.product
--				    AND dw.input_file != 'TV Writer'
--		) AS nw
--	WHERE nw.input_file IS NULL

	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
		--,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; estimate "' + nw.estimate +
		--'" matches with estimate on writer match file but input file is not TV Writer input file is ' + wdm.input_file
	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; Product "' + nw.estimate +
	    '" does not match with a existing entry under the TV Writer section. It does match with an entry in the "' + wdm.input_file +
	    '" section. Please add an entry to the TV Writer section for this Product name.'
	    ,GETDATE()
	FROM 
		dbo.STG_TV_Writer AS nw
		JOIN dbo.dim_writer_match AS wdm
			ON nw.estimate = wdm.estimate
			   AND wdm.input_file != 'TV Writer'
	WHERE nw.row_number NOT IN
						  (
						   SELECT 
							   srw.row_number
						   FROM 
							   STG_TV_Writer AS srw
							   JOIN dbo.dim_writer_match AS wdm
								   ON srw.product = wdm.product
									 AND wdm.input_file = 'TV Writer'
									 AND wdm.id_dim_date = @ID_DATE
						  ) 
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,wa.row_number
	    ,'On excel row ' + CONVERT(VARCHAR(10),wa.row_number + 1) + ';' + ' Lawson Code Part 2: "' + wa.media +
	    '" is not listed on Master Tracker Match File'
	    ,wa.filename
	FROM 
		dbo.STG_TV_Writer AS wa
		LEFT JOIN dim_media_type AS dt
			ON dt.media_type IN('OOH','TV')
	WHERE dt.media_type IS NULL

	
	--	If entry in “Media” (Column A) is “Other”, then for transferring to the “Master Tracker” Media Type is “OOH”.  If the entry is anything else, “Media Type” is “TV”


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

