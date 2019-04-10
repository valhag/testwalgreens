--	stored procedure name: usp_validate_SpotRadioWriter
--	description: usp that validates data about SpotRadio Writer file type
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
----		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 change STG_writerdigital_match to dim_writer_match
--	Date modification: 01/24/2019 INCLUDE VALIDATION FOR INPUT_FILE FIELD
--	Date modification: 01/30/2019 add validations about estimate matching between stg and dim_match and input_file
--	Date modification: 01/31/2019 validation 6 chars on gl_code
--	Date modification: 02/01/2019 messages update
--	Date modification: 02/14/2019 spot radio uses estimate and product to look up against writer match file
--	Date modification: 02/25/2019 remove empty rows and input_file validation
--	Date Modification 03/11/2019 error messages 
--	Date Modification 03/19/2019 error messages 

--	drop PROC [usp_validate_SpotRadioWriter]



CREATE PROC dbo.usp_validate_SpotRadioWriter (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN
	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT


	DELETE FROM STG_SpotRadioWriter
	WHERE 
		gl_code IS NULL
		AND product IS NULL
		AND estimate IS NULL
		AND month_of_service IS NULL



	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_SpotRadioWriter
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
							WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.',
							FILENAME) - 6,4)
							ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
						END
		    ,@CURRENTMONTH = CASE
							 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.',
							 FILENAME) - 6,2)
							 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
						 END
		FROM 
			STG_SpotRadioWriter
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'SpotRadio Writer PROCESS NO ROWS'
		SET @Folder = 'SpotRadio Writer NO ROWS'
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


	IF @FileName = 'SpotRadio Writer PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'SpotRadio Writer PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	DELETE FROM STG_SpotRadioWriter
	WHERE 
		billable IS NULL

	SELECT 
		*
	FROM 
		STG_SpotRadioWriter

	INSERT INTO dbo.Errors
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + '; estimate "' + srw.estimate +
	    ' input file is not must be SpotRadio Writer, change writer match file, incorrect input file is ' + wdm.input_file
	    ,GETDATE()
	FROM 
		dbo.STG_SpotRadioWriter AS srw
		JOIN dbo.dim_writer_match AS wdm
			ON srw.estimate = wdm.estimate
			   AND wdm.input_file != 'Spot Radio Writer'
	WHERE SRW.row_number NOT IN
						   (
						    SELECT 
							    srw.row_number
						    FROM 
							    STG_Writer_Radio AS srw
							    JOIN dbo.dim_writer_match AS wdm
								    ON srw.estimate = wdm.estimate
									  AND wdm.input_file = 'Spot Radio Writer'
						   ) 
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; Lawson Code Part 2 (gl_code) does not have at least 6 characters'
	    ,GETDATE()
	FROM 
		dbo.STG_SpotRadioWriter AS nw
	WHERE LEN(nw.gl_code) < 6
	UNION 

	--validation that veryfies the GL_code is not empty and that the estimate is not null. 
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + '; estimate or gl_code are not complete or do not have correct format or are empty'
	    ,GETDATE()
	FROM 
		dbo.STG_SpotRadioWriter AS srw
	WHERE gl_code IS NULL
		 OR estimate IS NULL
	UNION 
	-- validation to verify if estimate fields match between stg and di match tables
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; estimate "' + nw.estimate + '" & product "' + nw.product +
	    '" does not exist on Estimate Name Match File. If this combination is correct, the Estimate Name Match File should be updated.'
	    ,GETDATE()
	FROM 
		STG_SpotRadioWriter AS nw
	WHERE NOT EXISTS
				  (
				   SELECT 
					   1
				   FROM 
					   dim_writer_match AS dw
				   WHERE nw.estimate = dw.estimate
					    AND nw.product = dw.product
					    AND dw.id_dim_date = @ID_DATE
				  ) 
	UNION
	-- validation to verify the input file is valid
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; Estimate "' + nw.estimate + '" and Product "' + nw.product + '"' +
	    'does not match with a existing entry under the Spot Radio Writer section of the Estimate Name Match File. It does match with an entry in the "'
	    + wdm.input_file + '" section. Please add an entry to the Spot Radio Writer section for this Estimate name.'
	    ,GETDATE()
	FROM 
		dbo.STG_SpotRadioWriter AS nw
		JOIN dbo.dim_writer_match AS wdm
			ON nw.estimate = wdm.estimate
			   AND wdm.input_file != 'Spot Radio Writer'
	WHERE nw.row_number NOT IN
						  (
						   SELECT 
							   srw.row_number
						   FROM 
							   STG_SpotRadioWriter AS srw
							   JOIN dbo.dim_writer_match AS wdm
								   ON srw.estimate = wdm.estimate
									 AND wdm.input_file = 'Spot Radio Writer'
									 AND wdm.id_dim_date = @ID_DATE
						  ) 
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; the combination of Estimate "' + nw.stgestimate + ' & product "' + nw.
	    stgproduct +
	    '" does not exist in the Estimate Name Match File. If this combination is correct, the Estimate Name Match File should be updated. '
	    ,GETDATE()
	FROM
		(
		 SELECT 
			 s.row_number
			,d.estimate AS dimestimate
			,d.product AS dimproduct
			,s.estimate AS stgestimate
			,s.product AS stgproduct
		 FROM 
			 STG_SpotRadioWriter AS s
			 LEFT JOIN dim_writer_match AS d
				 ON s.product = d.product
				    AND s.estimate = d.estimate
				    AND d.id_dim_date = @ID_DATE
		) AS nw
	WHERE dimestimate IS NULL
		 OR dimproduct IS NULL
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,wa.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),wa.row_number + 1) + ';' + di.initiative_name + '" in combination with Lawson Code Part 2: "' + RIGHT
	    (gl_code,6) + '" is not on the Master Tracker Match file.  If this combination is correct, the Master Tracker Match File should be updated.'
	    ,wa.filename
	FROM 
		STG_SpotRadioWriter AS wa
		LEFT JOIN dim_writer_match AS dw
			ON dw.estimate = wa.estimate
			   AND dw.product = wa.product
			   AND dw.id_dim_date = @ID_DATE
		LEFT JOIN dim_initiative AS di
			ON di.initiative_name = dw.initiative
		LEFT JOIN dim_media_type AS dt
			ON dt.media_lawson = RIGHT(gl_code,6)
		LEFT JOIN dim_wag_initiative_media_type AS dwm
			ON dwm.id_initiative = di.id
			   AND dwm.id_media_type = dt.id
			   AND dwm.id_dim_date = @ID_DATE
	WHERE dwm.id_initiative IS NULL
		 OR dwm.id_media_type IS NULL
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,wa.row_number
	    ,'On excel row ' + CONVERT(VARCHAR(10),wa.row_number + 1) + ';' + ' Lawson Code Part 2: "' + RIGHT(gl_code,6) +
	    '" is not listed on Master Tracker Match File'
	    ,wa.filename
	FROM 
		dbo.STG_SpotRadioWriter AS wa
		LEFT JOIN dim_media_type AS dt
			ON dt.media_lawson = RIGHT(gl_code,6)
	WHERE dt.media_type IS NULL



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

