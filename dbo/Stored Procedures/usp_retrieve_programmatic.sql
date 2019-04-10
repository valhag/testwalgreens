
--drop PROCEDURE dbo.usp_retrieve_programmatic

--exec usp_retrieve_programmatic  9, 2018
--exec usp_retrieve_master_tracker 'N', 9, 2018

CREATE PROCEDURE dbo.usp_retrieve_programmatic
	--@puerto_rico_initiative_yn CHAR(1)
    --,
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

	IF OBJECT_ID('tempdb..#Dim_Date1') IS NOT NULL
	BEGIN
		DROP TABLE #Dim_Date1;
	END;

	WITH DATECTE(
		id_Dim_Date
	    ,month)
		AS (SELECT 
			    id_Dim_Date
			   ,month
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
			    id_Dim_Date
			   ,month
		    FROM 
			    Dim_Date
		    WHERE year IN (
					   @CURRENTYEAR
					  ,@CURRENTYEAR + 1
					  ,@CURRENTYEAR - 1)
				AND month BETWEEN 1 AND 8
				AND year = @CURRENTYEARFOLLOW)
		SELECT 
			id_Dim_Date
		    ,month
		INTO 
			#Dim_Date
		FROM 
			DATECTE AS d;

	DECLARE @PREVIOUSYEAR AS INT;
	SET @PREVIOUSYEAR = @CURRENTYEAR - 1;

	WITH DATECTE1(
		id_Dim_Date
	    ,month)
		AS (SELECT 
			    id_Dim_Date
			   ,month
		    FROM 
			    Dim_Date
		    WHERE year IN (
					   @CURRENTYEAR
					  ,@CURRENTYEAR + 1
					  ,@CURRENTYEAR - 1)
				AND month >= 9
				AND year = @CURRENTYEAR
		    UNION
		    SELECT 
			    id_Dim_Date
			   ,month
		    FROM 
			    Dim_Date
		    WHERE year IN (
					   @CURRENTYEAR
					  ,@CURRENTYEAR + 1
					  ,@CURRENTYEAR - 1)
				AND month BETWEEN 1 AND 8
				AND year = @CURRENTYEARFOLLOW - 1)
		SELECT 
			id_Dim_Date
		    ,month
		INTO 
			#Dim_Date1
		FROM 
			DATECTE1 AS d;


	WITH result_data(
		id_initiative
	    ,id_media_type
	    ,MAF
	    ,WAG
	    ,PREVIOUSBILLREGISTER
	    ,SEPMR
	    ,SEPMA
	    ,OCTMR
	    ,OCTMA
	    ,NOVMR
	    ,NOVMA
	    ,DECMR
	    ,DECMA
	    ,JANMR
	    ,JANMA
	    ,FEBMR
	    ,FEBMA
	    ,MARMR
	    ,MARMA
	    ,APRMR
	    ,APRMA
	    ,MAYMR
	    ,MAYMA
	    ,JUNMR
	    ,JUNMA
	    ,JULMR
	    ,JULMA
	    ,AUGMR
	    ,AUGMA)
		AS (SELECT 
			    pivot1.id_initiative
			   ,pivot1.id_media_type
			    --,SUM(ISNULL([0],0)) AS MAF
			    --,SUM(IIF(pivot1.id_type = 1,ISNULL([9],0),0)) AS SEPMA
			   ,SUM(IIF(pivot1.id_type = 1,ISNULL([13],0),0)) AS MAF
			   ,SUM(IIF(pivot1.id_type = 8,ISNULL([13],0),0)) AS WAG
			   ,SUM(IIF(pivot1.id_type = 14,ISNULL([14],0),0)) AS PREVIOUSBILLREGISTER
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([9],0),0)) AS SEPMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([9],0),0)) AS SEPMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([10],0),0)) AS OCTMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([10],0),0)) AS OCTMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([11],0),0)) AS NOVMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([11],0),0)) AS NOVMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([12],0),0)) AS DECMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([12],0),0)) AS DECMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([1],0),0)) AS JANMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([1],0),0)) AS JANMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([2],0),0)) AS FEBMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([2],0),0)) AS FEBMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([3],0),0)) AS MARMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([3],0),0)) AS MARMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([4],0),0)) AS APRMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([4],0),0)) AS APRMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([5],0),0)) AS MAYMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([5],0),0)) AS MAYMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([6],0),0)) AS JUNMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([6],0),0)) AS JUNMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([7],0),0)) AS JULMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([7],0),0)) AS JULMA
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([8],0),0)) AS AUGMR
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([8],0),0)) AS AUGMA
		    FROM
			    (
				SELECT 
					ISNULL(f.value,0) AS value
				    ,ISNULL(d.month,-1) AS month
				    ,dwm.id_initiative
				    ,dwm.id_media_type
				    ,f.id_type
				FROM 
					dbo.dim_wag_initiative_media_type AS dwm
					LEFT JOIN dbo.Fact_Outcome AS f
						ON f.id_initiative = dwm.id_initiative
						   AND f.id_media_type = dwm.id_media_type
						   AND f.id_time_generated IN(SELECT 
													id_Dim_Date
												FROM 
													Dim_Date
												WHERE year = @CURRENTYEAR
													 AND month IN (
															    @CURRENTMONTH
															   ,0) )
						   AND f.id_type IS NOT NULL
						   AND f.id_type != 1
					LEFT JOIN #Dim_Date AS d
						ON d.id_Dim_Date = f.id_time
				UNION
				SELECT 
					ISNULL(f.value,0) AS value
				    ,ISNULL(f.month,-1) AS month
					--, iif( f.id_type = 1, 0 ,iSNULL(d.month,0) ) AS month
				    ,dwm.id_initiative
				    ,dwm.id_media_type
				    ,f.id_type
				FROM 
					dim_wag_initiative_media_type AS dwm
					LEFT JOIN
							(
							 SELECT 
								 dwm.id
								,f.value
								,13 AS month
								,ISNULL(f.id_type,1) AS id_type
							 FROM 
								 dim_wag_initiative_media_type AS dwm
								 JOIN fact_outcome AS f
									 ON dwm.id_initiative = f.id_initiative
									    AND dwm.id_media_type = f.id_media_type
									    AND f.id_time =
													(
													 SELECT 
														 id_dim_date
													 FROM 
														 dim_date
													 WHERE year = @CURRENTYEAR
														  AND month = @CURRENTMONTH
													) 
								 LEFT JOIN #Dim_Date AS d
									 ON d.id_Dim_Date = f.id_time
							 WHERE id_type IN (
										   1
										  ,8)
							) AS f
						ON f.id = dwm.id
				UNION
				SELECT 
					SUM(f.value)
				    ,14
				    ,f.id_initiative
				    ,f.id_media_type
				    ,14 AS id_type
				FROM 
					Fact_Outcome AS f
					JOIN #Dim_Date1 AS d
						ON d.id_Dim_Date = f.id_time
				WHERE id_type = 12
				GROUP BY 
					f.id_initiative
				    ,f.id_media_type
			    ) AS data1 PIVOT(MAX(data1.value) FOR data1.month IN(
			    [0]
			   ,[1]
			   ,[2]
			   ,[3]
			   ,[4]
			   ,[5]
			   ,[6]
			   ,[7]
			   ,[8]
			   ,[9]
			   ,[10]
			   ,[11]
			   ,[12]
			   ,[13]
			   ,[14])) AS pivot1
		    GROUP BY 
			    pivot1.id_initiative
			   ,pivot1.id_media_type)
		SELECT 
			dw.id AS MAF#
		    ,dw.wag_forecast_initiative AS [WAG Forecast Initiative]
		    ,dw.lawson AS Lawson
		    ,di.initiative_name AS Initiative
		    ,dm.media_type AS [Media Type]
		    ,dm.media_lawson AS [Media Lawson]
		    ,t2.MAF AS [Annual MAF]
		    ,t2.SEPMR AS [SEPT Mediacom Register]
		    ,t2.SEPMA AS [SEPT WAG Actual]
		    ,t2.OCTMR AS [OCT Mediacom Register]
		    ,t2.OCTMA AS [OCT WAG Actual]
		    ,t2.NOVMR AS [NOV Mediacom Register]
		    ,t2.NOVMA AS [NOV WAG Actual]
		    ,t2.DECMR AS [DEC Mediacom Register]
		    ,t2.DECMA AS [DEC WAG Actual]
		    ,t2.JANMR AS [JAN Mediacom Register]
		    ,t2.JANMA AS [JAN WAG Actual]
		    ,t2.FEBMR AS [FEB Mediacom Register]
		    ,t2.FEBMA AS [FEB WAG Actual]
		    ,t2.MARMR AS [MAR Mediacom Register]
		    ,t2.MARMA AS [MAR WAG Actual]
		    ,t2.APRMR AS [APR Mediacom Register]
		    ,t2.APRMA AS [APR WAG Actual]
		    ,t2.MAYMR AS [MAY Mediacom Register]
		    ,t2.MAYMA AS [MAY WAG Actual]
		    ,t2.JUNMR AS [June Mediacom Register]
		    ,t2.JUNMA AS [June WAG Actual]
		    ,t2.JULMR AS [July Mediacom Register]
		    ,t2.JULMA AS [July WAG Actual]
		    ,t2.AUGMR AS [AUG Mediacom Register]
		    ,t2.AUGMA AS [AUG WAG Actual]
		    ,t2.WAG AS [WAG Adjustments]
		    ,t2.PREVIOUSBILLREGISTER AS [PREVIOUSBILLREGISTER]
		FROM 
			result_data AS t2
			INNER JOIN dim_initiative AS di
				ON di.id = t2.id_initiative
				   --AND di.puerto_rico_initiative_yn = @puerto_rico_initiative_yn
			INNER JOIN dim_wag_forecast_initiative AS dw
				ON dw.id = di.id_wag_forecast_initiative
			INNER JOIN dim_media_type AS dm
				ON dm.id = t2.id_media_type
				and dm.media_type = 'Programmatic'
		ORDER BY 
			dw.id
END

