--	stored procedure name: usp_validate_PuertoRico
--	description: usp that generates data on fact_outcome table puerto rico file type
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
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/22/2019 month names change
--	Date Modification 03/04/2019 remove auto sum rows
--	Date Modification 03/19/2019 error messages

--	drop PROC [usp_validate_PuertoRico]


CREATE PROC dbo.usp_validate_PuertoRico (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN
	--*******************************************************************************************************************************************************************************************************************************/

	--**************************************************************************************** DECLARE & SET VARIABLES *************************************************************************************************************

	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT




	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_PuertoRico
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
			STG_PuertoRico
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
		SET @FileName = 'Puerto Rico PROCESS NO ROWS'
		SET @Folder = 'Puerto Rico NO ROWS'

	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Puerto Rico PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Puerto Rico PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	-- remove auto sum rows
	DELETE STG_PuertoRico
	FROM STG_PuertoRico stg
	WHERE 
		stg.row_number IN
					   (
					    SELECT 
						    row_number
					    FROM 
						    STG_PuertoRico
					    WHERE initiative LIKE '%Auto Sum%'
					   ) 

	INSERT INTO ERRORS
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,pt.row_number
		--,'Error: Combination with ' + ISNULL(pt.initiative,'[Blank]') + ' initative and Media type: ' + ISNULL(pt.media_type,'[Blank]') +
		--' , does not exist  on Master Tracker.'
	    ,'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; The combination of Initiative "' + ISNULL(pt.initiative,'[Blank]') +
	    '" (as matched from MAF Match File) and media type "' + ISNULL(pt.media_type,'[Blank]') + '" does not exist on Master Tracker'
	    ,GETDATE()
	FROM 
		dbo.STG_PuertoRico AS pt
		LEFT JOIN
				(
				 SELECT 
					 di.initiative_name
					,mt.media_type
				 FROM 
					 dbo.dim_wag_initiative_media_type AS im
					 INNER JOIN dbo.dim_media_type AS mt
						 ON im.id_media_type = mt.id
					 INNER JOIN dbo.dim_initiative AS di
						 ON im.id_initiative = di.id
				) AS imt
			ON pt.initiative = imt.initiative_name
			   AND pt.media_type = imt.media_type
	WHERE (imt.initiative_name IS NULL
		  OR imt.media_type IS NULL)
		 AND COALESCE(sep_mediacom_register,oct_mediacom_register,nov_mediacom_register,dec_mediacom_register,jan_mediacom_register,
		 feb_mediacom_register,mar_mediacom_register,apr_mediacom_register,may_mediacom_register,jun_mediacom_register,jul_mediacom_register,
		 aug_mediacom_register) IS NOT NULL
		 AND pt.row_number IS NOT NULL
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,row_number
	    ,'On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; The combination initiative "' + ISNULL(pt.initiative,'[Blank]') +
	    '" & media type "' + ISNULL(pt.media_type,'[Blank]') + '" is duplicated, remove duplicated rows.'
		--,'Error: Combination with ' + ISNULL(pt.initiative,'[Blank]') + ' initative and Media type: ' + ISNULL(pt.media_type,'[Blank]') +
		--' , are duplicated'
	    ,GETDATE()
	FROM 
		dbo.STG_PuertoRico AS pt
		INNER JOIN
				 (
				  SELECT 
					  initiative
					 ,media_type
					 ,COUNT(*) AS RepCount
				  FROM 
					  dbo.STG_PuertoRico
				  GROUP BY 
					  initiative
					 ,media_type
				  HAVING COUNT(*) > 1
				 ) AS ct
			ON pt.initiative = ct.initiative
			   AND pt.media_type = ct.media_type
	UNION
	SELECT 
		@ExecutionID
	    ,sw.filename
	    ,sw.row_number
	    ,' On excel row; ' + CONVERT(VARCHAR(10),row_number + 1) + '; Lawson code Part 2 does not have at least 6 characters' 
	    ,GETDATE()
	FROM 
		STG_PuertoRico AS sw
	WHERE LEN(media_lawson) < 6
	UNION
	SELECT 
		@ExecutionID
	    ,sw.filename
	    ,sw.row_number
	    ,' On excel row; ' + CONVERT(VARCHAR(10),row_number + 1) + '; Lawson code Part 2 "' + media_lawson + '" is not listed on Master Tracker Match file'
	    ,GETDATE()
	FROM 
		STG_PuertoRico sw
	WHERE sw.media_lawson NOT IN
						 (
						  SELECT 
							  media_lawson
						  FROM 
							  dim_media_type
						 )



	--********************************************************************************************************************************************************************************************************************************/

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

