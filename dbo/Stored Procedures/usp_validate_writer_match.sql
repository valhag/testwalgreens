--	stored procedure name: usp_validate_writer_match
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
--	Date Modification: 02/08/2019 validate avoid duplicated estimates
--	Date Modification: 02/14/2019 remove empty rows
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/19/2019 duplicated rows are estimate+product+input_file
--	Date Modification 03/11/2019 ISSUE 36
--	Date Modification 03/19/2019 error messages

--	drop PROC [usp_validate_writer_match]

CREATE PROC dbo.usp_validate_writer_match (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN
	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT



	DELETE FROM STG_writerdigital_match
	WHERE 
		input_file IS NULL
		AND estimate IS NULL
		AND product IS NULL
		AND initiative IS NULL

	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_writerdigital_match
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
			STG_writerdigital_match
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'Writer Match PROCESS NO ROWS'
		SET @Folder = 'Writer Match PROCESS NO ROWS'
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


	IF @FileName = 'Writer Match PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Writer Match PROCESS NO ROWS'
			 ,GETDATE()) 
	END


	INSERT INTO ERRORS
	SELECT 
		@ExecutionID
	    ,d.filename
	    ,d.row_number
	    ,' On Excel row, ' + CONVERT(VARCHAR(10),row_number + 1) + '; The Combination of Estimate "' + d.estimate + '"; Product "' + d.product + '" & Input File "' + d
	    .input_file + '" is duplicated '
	    ,GETDATE()
	FROM 
		STG_writerdigital_match AS d
		JOIN
			(
			 SELECT 
				 isnull(estimate,'') as estimate
				,isnull(product,'') as product
				,isnull(input_file,'') as input_file
			 FROM 
				 STG_writerdigital_match
			 GROUP BY 
				 estimate
				,product
				,input_file
			 HAVING COUNT(*) > 1
			) AS x
			ON isnull(d.estimate,'') = x.estimate
			   AND isnull(d.product,'') = x.product
			   AND isnull(d.input_file,'') = x.input_file
	UNION
	SELECT 
		@ExecutionID
	    ,@filename
	    ,stg.row_number + 1
	    ,'On Excel row' + CONVERT(VARCHAR(10),row_number + 1) + '; Initiative "' + stg.initiative + '" does not exist on Master Tracker Match File.'
	    ,getdate()
	FROM 
		STG_writerdigital_match AS stg
	WHERE stg.initiative NOT IN
						   (
						    SELECT 
							    initiative_name
						    FROM 
							    dim_initiative
						   )
	ORDER BY 
		row_number





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

