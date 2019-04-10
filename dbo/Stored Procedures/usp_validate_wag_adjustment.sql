--	stored procedure name: usp_validate_wag_adjustment
--	description: usp that validates data about wag adjustment file type
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
----		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/21/2019 allowing . on filename 
--	Date Modification 03/11/2019 error messages 
--	Date Modification 03/19/2019 error messages 

--	drop PROC [usp_validate_wag_adjustment]

CREATE PROC usp_validate_wag_adjustment (
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
				 STG_WAG_Adjustment
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
						WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,4)
						ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
					END
		    ,@CURRENTMONTH =  CASE
						 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,2)
						 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
					 END
		FROM 
			STG_WAG_Adjustment
			select @ID_DATE = id_Dim_Date  from Dim_Date where month = @CURRENTMONTH and year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'Wag Adjustment PROCESS NO ROWS'
		SET @Folder = 'Wag Adjustment NO ROWS'
		select @ID_DATE = id_Dim_Date  from Dim_Date where month = month(getdate()) and year = year(getdate())

	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Wag Adjustment PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Wag Adjustment PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO Errors --Insertin into Errors table
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,row_number + 1
	    ,error
	    ,GETDATE() AS TimeStamp
	FROM
		(
		 SELECT 
			 ResultSet.row_number
			,' On excel row ' + CONVERT(VARCHAR(10),row_number) + ResultSet.error AS error
			,ResultSet.filename
		 FROM
			 (
			 --Non initiative
			 /*SELECT 
				 wa.row_number
				,ISNULL(CASE
						   WHEN di.initiative_name IS NULL THEN ' Initiative name "' + wa.initiative + '" is not on Master Tracker Match File'
					   END,'') AS error
				,wa.filename
			 FROM 
				 dbo.STG_WAG_Adjustment AS wa
				 LEFT JOIN dim_initiative AS di
					 ON di.initiative_name = wa.initiative
			 WHERE di.initiative_name IS NULL
			 UNION*/
			 SELECT 
				 wa.row_number 
				,ISNULL(CASE
						   WHEN len(wa.media_lawson_lawson_code_part_2) < 6 THEN ' Lawson Code Part 2 does not have at least 6 characters'
					   END,'') AS error
				,wa.filename
			 FROM 
				 dbo.STG_WAG_Adjustment AS wa
				 WHERE LEN(wa.media_lawson_lawson_code_part_2) < 6
			 UNION 
			 --Non Media Type
			 SELECT 
				 wa.row_number
				,ISNULL(CASE
						   WHEN dt.media_type IS NULL THEN ' Lawson Code Part 2: "' + wa.media_lawson_lawson_code_part_2 +
						   '" is not listed on Master Tracker Match File'
					   END,'') AS error_media_type
				,wa.filename
			 FROM 
				 dbo.STG_WAG_Adjustment AS wa
				 LEFT JOIN dim_media_type AS dt
					 ON dt.media_lawson = wa.media_lawson_lawson_code_part_2
			 WHERE dt.media_type IS NULL
			 UNION
			 --Non Initiative and Media Type Combination
			 SELECT 
				 wa.row_number
				,ISNULL(CASE
						   WHEN dwm.id_initiative IS NULL
							   AND dwm.id_media_type IS NULL THEN ' The Initiative "' + wa.initiative +
							   '" in combination with Lawson Code Part 2: "' + wa.media_lawson_lawson_code_part_2 + '" is not on the Master Tracker Match file.  If this combination  is correct, the Master Tracker Match File should be updated.'
					   END,'') AS error_initiative_media_type_combination
				,wa.filename
			 FROM 
				 dbo.STG_WAG_Adjustment AS wa
				 LEFT JOIN dim_initiative AS di
					 ON di.initiative_name = wa.initiative
				 LEFT JOIN dim_media_type AS dt
					 ON dt.media_lawson = wa.media_lawson_lawson_code_part_2
				 LEFT JOIN dim_wag_initiative_media_type AS dwm
					 ON dwm.id_initiative = di.id
					    AND dwm.id_media_type = dt.id
			 WHERE dwm.id_initiative IS NULL
				  OR dwm.id_media_type IS NULL
			 ) AS ResultSet
		 --order by row_number
		) AS RS
	

	
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
END
