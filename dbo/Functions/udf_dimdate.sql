--drop function udf_dimdate fdgfdgfd


CREATE FUNCTION dbo.udf_dimdate(@CURRENTMONTH INT
    ,@CURRENTYEAR INT)
RETURNS @ReturnTable TABLE (id_Dim_Date int, month int,year int)
AS 
BEGIN

    DECLARE @YEARINI INT
	DECLARE @YEAREND INT


	IF @CURRENTMONTH >= 9
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 1 
		SET @YEAREND = @CURRENTYEAR  
	END
		ELSE
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 2
		SET @YEAREND = @CURRENTYEAR - 1
	END



	IF @CURRENTMONTH >= 9
	BEGIN
		SET @YEARINI = @CURRENTYEAR  
		SET @YEAREND = @CURRENTYEAR + 1 
	END
		ELSE
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 1
		SET @YEAREND = @CURRENTYEAR 
	END


       INSERT INTO @ReturnTable
	SELECT 
			    id_Dim_Date
			    ,month
			    ,year
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEARINI)
				AND month >= 9
				AND year = @YEARINI
		   UNION
		    SELECT 
			    id_Dim_Date
			   ,month
			   ,year
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEAREND)
				AND month BETWEEN 1 AND 8
				AND year = @YEAREND
	
       RETURN
END
