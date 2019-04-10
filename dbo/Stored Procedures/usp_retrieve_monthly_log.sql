--drop proc usp_retrieve_monthly_log
-- exec usp_retrieve_monthly_log 10, 2018

CREATE PROC usp_retrieve_monthly_log
@CURRENTMONTH INT
,@CURRENTYEAR INT
AS
BEGIN

    DECLARE @CURRENTYEARFOLLOW INT;
	DECLARE @CURRENTYEARPREVIOUS INT

	IF @CURRENTMONTH >= 9
	BEGIN
		SET @CURRENTYEARFOLLOW = @CURRENTYEAR + 1
		SET @CURRENTYEARPREVIOUS = @CURRENTYEAR

	END
		ELSE
	BEGIN
		SET @CURRENTYEARFOLLOW = @CURRENTYEAR
		SET @CURRENTYEARPREVIOUS = @CURRENTYEAR - 1
	END;

	IF OBJECT_ID('tempdb..#Dim_Date') IS NOT NULL
	BEGIN
		DROP TABLE #Dim_Date;
	END;

	WITH DATECTE(
		id_Dim_Date, month)
		AS (SELECT 
			    id_Dim_Date, month
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
			    id_Dim_Date, month
		    FROM 
			    Dim_Date
		    WHERE year IN (
					   @CURRENTYEAR
					  ,@CURRENTYEAR + 1
					  ,@CURRENTYEAR - 1)
				AND month BETWEEN 1 AND 8
				AND year = @CURRENTYEARFOLLOW)
		SELECT 
			id_Dim_Date, month
		INTO 
			#Dim_Date
		FROM 
			DATECTE AS d
		WHERE id_DIM_DATE <=
						 (
						  SELECT 
							  id_DIM_DATE
						  FROM 
							  Dim_Date
						  WHERE year = @CURRENTYEAR
							   AND month = @CURRENTMONTH
						 ) 
						
	


	 SELECT 
		 FileName AS [File Name]
		,Folder
		,convert(varchar(16),EndTime,120) AS Timestamp
		,STATUS
	 FROM 
		 ExecutionLog e
	   JOIN #Dim_Date D on e.Id_date = d.id_Dim_Date
	   
	 ORDER BY 
		 ExecutionID DESC
	
END
