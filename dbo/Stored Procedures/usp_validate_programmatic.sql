--		stored procedure name: usp_validate_programmatic
--	description: usp that generates data on dim_wag_initiative_media_type
--		  (where the relationships between initiatives and media types are saved)
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date modification: 06/02/2019 CHANGE ORDER OF THE SHOWED ERRORS.
--	Date Modification 02/15/2019 allowing . on filename
--	Date Modification 03/04/2019 allowing . on filename v2

--	drop PROC [usp_validate_programmatic]

CREATE PROC dbo.usp_validate_programmatic (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN

	DECLARE @ID_DATE AS INT

	DELETE FROM STG_Programmatic
	WHERE 
		sepstring = ''
		AND octstring = ''
		AND novstring = ''
		AND decstring = ''
		AND janstring = ''
		AND febstring = ''
		AND marstring = ''
		AND aprstring = ''
		AND maystring = ''
		AND junstring = ''
		AND julstring = ''
		AND augstring = ''
		OR initiative = ''


	DECLARE @Folder AS VARCHAR(100)
	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_Programmatic
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
							WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,4)
							ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
						END
		    ,@CURRENTMONTH = CASE
							 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,2)
							 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
						 END
		FROM 
			STG_Programmatic
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = MONTH(GETDATE())
			 AND year = YEAR(GETDATE())
		SET @FileName = 'Programmatic PROCESS NO ROWS'
		SET @Folder = 'Programmatic PROCESS NO ROWS'

	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Programmatic PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Programmatic PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO Errors
	/*SELECT 
		@ExecutionID
	    ,@FileName
	    ,CONVERT(VARCHAR(10),mval.row_number + 1) AS 'Row Number'
	    ,'On excel row ' + CONVERT(VARCHAR(10),mval.row_number + 1) + '; initiative: "' + mval.initiative +
	    '"  does not exist on Master Tracker Match File' AS 'Error'
	    ,GETDATE()
	FROM
		(
		 SELECT 
			 sp.row_number
			,sp.initiative
		 FROM 
			 dim_initiative AS di
			 RIGHT JOIN
					  (
					   SELECT 
						   row_number
						  ,initiative
					   FROM 
						   STG_Programmatic
					   WHERE initiative IS NOT NULL
						    AND COALESCE(sepstring,octstring,novstring,decstring,janstring,febstring,marstring,aprstring,maystring,junstring,
						    julstring,augstring) IS NOT NULL
					  ) AS sp
				 ON di.initiative_name = sp.initiative
		 WHERE di.id IS NULL
		) AS mval
	UNION*/
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,CONVERT(VARCHAR(10),row_number + 1) AS 'Row Number'
	    ,'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + ';' + CASE
															  WHEN COALESCE(dim.id_media_type,dim.id_initiative) IS NULL THEN
															  ' The combination of Initiative "' + prog.initiative + '" (as matched from MAR Match File ) and media type "Programmatic" does not exist on Master Tracker'
														  END AS 'Error'
	    ,GETDATE()
	FROM 
		dim_wag_initiative_media_type AS dim
		RIGHT JOIN
				 (
				  SELECT 
					  sp.row_number
					 ,di.id
					 ,sp.initiative
				  FROM 
					  dim_initiative AS di
					  RIGHT JOIN
							   (
							    SELECT 
								    row_number
								   ,initiative
							    FROM 
								    STG_Programmatic
							    WHERE initiative IS NOT NULL
									AND COALESCE(sepstring,octstring,novstring,decstring,janstring,febstring,marstring,aprstring,maystring,
									junstring,julstring,augstring) IS NOT NULL
							   ) AS sp
						  ON di.initiative_name = sp.initiative
				 ) AS prog
			ON prog.id = dim.id_initiative
			   AND dim.id_media_type IN(SELECT 
									   id
								   FROM 
									   dim_media_type
								   WHERE media_type = 'Programmatic')
	WHERE dim.id_media_type IS NULL
		 OR dim.id_initiative IS NULL
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,CONVERT(VARCHAR(10),row_number + 1) AS 'Row Number'
	    ,'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; Initiative ' + initiative + ' is duplicated, remove duplicated rows'
	    ,GETDATE()
	FROM 
		STG_Programmatic
	WHERE initiative IN
					(
					 SELECT 
						 initiative
					 FROM 
						 STG_Programmatic
					 WHERE initiative IS NOT NULL
						  AND COALESCE(sepstring,octstring,novstring,decstring,janstring,febstring,marstring,aprstring,maystring,junstring,
						  julstring,augstring) IS NOT NULL
					 GROUP BY 
						 initiative
					 HAVING COUNT(*) > 1
					) 



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
