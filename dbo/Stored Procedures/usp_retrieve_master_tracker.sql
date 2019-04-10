--	stored procedure name: usp_retrieve_master_tracker
--	description: usp that RETRIEVES DATA (insert/update) data from fact_outcome to generate master tracker files
--	author: HVA
--	Date Creation: 20/11/2018
--	Date Creation: 01/25/2019 fix 
--	Date Modification: 02/01/2019 fix september wag actual to include type 11
--	Date Modification: 02/13/2019 issue 17 outcome order
--	Date Modification: 02/13/2019 issue 22 bill register previous year is showing info on final master tracker
--	Date Modification: 02/20/2019 maf new procedure
--	Date Modification: 02/22/2019 OPTIMIZATION
--	Date Modification: 03/05/2019 retrieve bill register

-- DROP PROCEDURE [dbo].[usp_retrieve_master_tracker]
--exec usp_retrieve_master_tracker null, 11, 2018
--exec usp_retrieve_master_tracker 'n', 9, 2018, 'Programmatic'
--exec usp_retrieve_master_tracker 'n', 9, 2018, 'MAF'
--exec usp_retrieve_master_tracker 'y', 10, 2018
--SELECT * FROM DIM_TYPE 
--exec usp_retrieve_master_tracker  @CURRENTMONTH= 9,  @CURRENTYEAR= 2018, @media_type ='Programmatic'
--exec usp_retrieve_master_tracker  @puerto_rico_initiative_yn= 'N', @CURRENTMONTH= 9,  @CURRENTYEAR= 2018
--exec usp_retrieve_master_tracker  @puerto_rico_initiative_yn= 'Y', @CURRENTMONTH= 9,  @CURRENTYEAR= 2018

CREATE PROCEDURE dbo.usp_retrieve_master_tracker 
	@puerto_rico_initiative_yn CHAR(1) = NULL
    ,@CURRENTMONTH INT
    ,@CURRENTYEAR INT
    ,@media_type VARCHAR(50) = NULL
AS
BEGIN


	DECLARE @ID_DIM_DATE INT

	SELECT 
		@ID_DIM_DATE = id_Dim_Date
	FROM 
		Dim_Date
	WHERE YEAR = @CURRENTYEAR
		 AND MONTH = @CURRENTMONTH

	DECLARE @YEARINI INT
	DECLARE @YEAREND INT


	-- #Dim_DateCurrentYear contains months of current fiscal year defined by current month and current year parameters
	IF OBJECT_ID('tempdb..#Dim_DateCurrentYear') IS NOT NULL
	BEGIN
		DROP TABLE #Dim_DateCurrentYear;
	END;

	-- #Dim_DatePreviousYear contains months of previous fiscal year defined by current month and current year parameters
	IF OBJECT_ID('tempdb..#Dim_DatePreviousYear') IS NOT NULL
	BEGIN
		DROP TABLE #Dim_DatePreviousYear;
	END;

	IF @CURRENTMONTH >= 9
	BEGIN
		SET @YEARINI = @CURRENTYEAR
		SET @YEAREND = @CURRENTYEAR + 1
	END
		ELSE
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 1
		SET @YEAREND = @CURRENTYEAR
	END;


	WITH DATECTE(
		id_Dim_Date
	    ,month)
		AS (SELECT 
			    id_Dim_Date
			   ,month
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEARINI)
				AND month >= 9
				AND year = @YEARINI
		    UNION
		    SELECT 
			    id_Dim_Date
			   ,month
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEAREND)
				AND month BETWEEN 1 AND 8
				AND year = @YEAREND)
		SELECT 
			id_Dim_Date
		    ,month
		INTO 
			#Dim_DateCurrentYear
		FROM 
			DATECTE AS d;


	IF @CURRENTMONTH >= 9
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 1
		SET @YEAREND = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @YEARINI = @CURRENTYEAR - 2
		SET @YEAREND = @CURRENTYEAR - 1
	END;

	WITH DATECTE1(
		id_Dim_Date
	    ,month)
		AS (SELECT 
			    id_Dim_Date
			   ,month
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEARINI)
				AND month >= 9
				AND year = @YEARINI
		    UNION
		    SELECT 
			    id_Dim_Date
			   ,month
		    FROM 
			    Dim_Date
		    WHERE year IN (@YEAREND)
				AND month BETWEEN 1 AND 8
				AND year = @YEAREND)
		SELECT 
			id_Dim_Date
		    ,month
		INTO 
			#Dim_DatePreviousYear
		FROM 
			DATECTE1 AS d;

    -- following cte retrieves the information of fact_outcome table 
	WITH result_data(
		id_initiative
	    ,id_media_type
	    ,MAF
	    ,WAG
	    ,PREVIOUSBILLREGISTER
	    ,SEPMR
	    ,SEPMRBR
	    ,SEPMA
	    ,OCTMR
	    ,OCTMRBR
	    ,OCTMA
	    ,NOVMR
	    ,NOVMRBR
	    ,NOVMA
	    ,DECMR
	    ,DECMRBR
	    ,DECMA
	    ,JANMR
	    ,JANMRBR
	    ,JANMA
	    ,FEBMR
	    ,FEBMRBR
	    ,FEBMA
	    ,MARMR
	    ,MARMRBR
	    ,MARMA
	    ,APRMR
	    ,APRMRBR
	    ,APRMA
	    ,MAYMR
	    ,MAYMRBR
	    ,MAYMA
	    ,JUNMR
	    ,JUNMRBR
	    ,JUNMA
	    ,JULMR
	    ,JULMRBR
	    ,JULMA
	    ,AUGMR
	    ,AUGMRBR
	    ,AUGMA)
		AS (SELECT 
			    pivot1.id_initiative
			   ,pivot1.id_media_type
			   ,SUM(IIF(pivot1.id_type = 1,ISNULL([13],0),0)) AS MAF                          -- maf data one column
			   ,SUM(IIF(pivot1.id_type = 8,ISNULL([13],0),0)) AS WAG					  -- wag adjustment data one column
			   ,SUM(IIF(pivot1.id_type = 14,ISNULL([14],0),0)) AS PREVIOUSBILLREGISTER		  -- previous fiscal year bill register data one column
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([9],0),0)) AS SEPMR			  -- september media register without external wag, maf and external wag [9] is month 9 september
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([9],0),0)) AS SEPMRBR			       -- september media register bill register (12)
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([9],0),0)) AS SEPMA					  -- september external wag(11)
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([10],0),0)) AS OCTMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([10],0),0)) AS OCTMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([10],0),0)) AS OCTMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([11],0),0)) AS NOVMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([11],0),0)) AS NOVMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([11],0),0)) AS NOVMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([12],0),0)) AS DECMR			  
			   ,SUM(IIF(pivot1.id_type NOT IN(12),ISNULL([12],0),0)) AS DECMRBR			  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([12],0),0)) AS DECMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([1],0),0)) AS JANMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([1],0),0)) AS JANMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([1],0),0)) AS JANMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([2],0),0)) AS FEBMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([2],0),0)) AS FEBMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([2],0),0)) AS FEBMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([3],0),0)) AS MARMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([3],0),0)) AS MARMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([3],0),0)) AS MARMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([4],0),0)) AS APRMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([4],0),0)) AS APRMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([4],0),0)) AS APRMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([5],0),0)) AS MAYMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([5],0),0)) AS MAYMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([5],0),0)) AS MAYMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([6],0),0)) AS JUNMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([6],0),0)) AS JUNMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([6],0),0)) AS JUNMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([7],0),0)) AS JULMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([7],0),0)) AS JULMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([7],0),0)) AS JULMA					  
			   ,SUM(IIF(pivot1.id_type NOT IN(11,1,8),ISNULL([8],0),0)) AS AUGMR			  
			   ,SUM(IIF(pivot1.id_type IN(12),ISNULL([8],0),0)) AS AUGMRBR				  
			   ,SUM(IIF(pivot1.id_type = 11,ISNULL([8],0),0)) AS AUGMA					  
		    FROM
			    (
				SELECT --- select retrieves all data type except maf, bill register and wag adjustment
					ISNULL(fff.value,0) AS value
				    ,ISNULL(fff.month,-1) AS month
				    ,dwm.id_initiative
				    ,dwm.id_media_type
				    ,fff.id_type
				FROM 
					dbo.dim_wag_initiative_media_type AS dwm
					LEFT JOIN
							(
							 SELECT 
								 f.id_initiative
								,f.id_media_type
								,f.id_time
								,f.id_time_generated
								,f.id_type
								,f.value
								,ISNULL(DD.month,-1) AS month
							 FROM 
								 Fact_Outcome AS f
								 JOIN
									 (
									  SELECT 
										  f.id_initiative
										 ,f.id_media_type
										 ,f.id_time
										 ,MAX(id_time_generated) AS id_time_generated
										 ,f.id_type
									  FROM 
										  dbo.Fact_Outcome AS f
										  JOIN #Dim_DateCurrentYear AS DD
											  ON f.id_time = DD.id_Dim_Date
									  WHERE f.id_type NOT IN (
														1
													    ,8
													    ,12)
										   AND id_time_generated <=
															   (
															    SELECT 
																    D.id_Dim_Date
															    FROM 
																    Dim_Date AS D
																    JOIN #Dim_DateCurrentYear AS DD
																	    ON D.id_Dim_Date = dd.id_Dim_Date
															    WHERE D.year = @CURRENTYEAR
																	AND D.month = @CURRENTMONTH
															   )
									  GROUP BY 
										  f.id_initiative
										 ,f.id_media_type
										 ,f.id_time
										 ,f.id_type
									 ) AS ff
									 ON f.id_initiative = ff.id_initiative
									    AND f.id_type = ff.id_type
									    AND f.id_time = ff.id_time
									    AND f.id_initiative = ff.id_initiative
									    AND f.id_media_type = ff.id_media_type
									    AND f.id_time_generated = ff.id_time_generated
								 JOIN #Dim_DateCurrentYear AS DD
									 ON DD.id_Dim_Date = f.id_time
							) AS fff
						ON fff.id_initiative = dwm.id_initiative
						   AND fff.id_media_type = dwm.id_media_type
				WHERE dwm.id_dim_date = @ID_DIM_DATE
				UNION
				SELECT --- select bill register values (current month and previous)
					ISNULL(fff.value,0) AS value
				    ,ISNULL(fff.month,-1) AS month
				    ,dwm.id_initiative
				    ,dwm.id_media_type
				    ,fff.id_type
				FROM 
					dbo.dim_wag_initiative_media_type AS dwm
					LEFT JOIN
							(
							 SELECT 
								 f.id_initiative
								,f.id_media_type
								,f.id_time
								,f.id_time_generated
								,f.id_type
								,f.value
								,ISNULL(DD.month,-1) AS month
							 FROM 
								 Fact_Outcome AS f
								 JOIN
									 (
									  SELECT 
										  f.id_initiative
										 ,f.id_media_type
										 ,f.id_time
										 ,MAX(id_time_generated) AS id_time_generated
										 ,f.id_type
									  FROM 
										  dbo.Fact_Outcome AS f
										  JOIN #Dim_DateCurrentYear AS DD
											  ON f.id_time = DD.id_Dim_Date
									  WHERE f.id_type IN (12)
										   --AND id_time_generated = @ID_DIM_DATE 
										   AND id_time_generated <=
															   (
															    SELECT 
																    D.id_Dim_Date
															    FROM 
																    Dim_Date AS D
																    JOIN #Dim_DateCurrentYear AS DD
																	    ON D.id_Dim_Date = dd.id_Dim_Date
															    WHERE D.year = @CURRENTYEAR
																	AND D.month = @CURRENTMONTH
															   )
									  GROUP BY 
										  f.id_initiative
										 ,f.id_media_type
										 ,f.id_time
										 ,f.id_type
									 ) AS ff
									 ON f.id_initiative = ff.id_initiative
									    AND f.id_type = ff.id_type
									    AND f.id_time = ff.id_time
									    AND f.id_initiative = ff.id_initiative
									    AND f.id_media_type = ff.id_media_type
									    AND f.id_time_generated = ff.id_time_generated
								 JOIN #Dim_DateCurrentYear AS DD
									 ON DD.id_Dim_Date = f.id_time
							) AS fff
						ON fff.id_initiative = dwm.id_initiative
						   AND fff.id_media_type = dwm.id_media_type
				WHERE dwm.id_dim_date = @ID_DIM_DATE
				UNION
				-- retrieves maf and wag_adjustment ONE column fields
				SELECT 
					ISNULL(f.value,0) AS value
				    ,ISNULL(f.month,-1) AS month
				    ,f.id_initiative
				    ,f.id_media_type
				    ,f.id_type
				FROM 
					dim_wag_initiative_media_type AS dwm
					JOIN #Dim_DateCurrentYear AS ddd
						ON ddd.id_Dim_Date = dwm.id_dim_date
					LEFT JOIN
							(
							 SELECT 
								 ISNULL(f.value,0) AS value
								,ISNULL(mafwag.month,-1) AS month
								,f.id_initiative
								,f.id_media_type
								,f.id_type
								,mafwag.id
							 FROM 
								 fact_outcome AS f
								 LEFT JOIN
										 (
										  SELECT 
											  dwm.id
											 ,dwm.id_initiative
											 ,dwm.id_media_type
											 ,f.id_time
											 ,f.id_type
											 ,13 AS month
										  FROM 
											  dim_wag_initiative_media_type AS dwm
											  LEFT JOIN
													  (
													   SELECT 
														   dwm.id
														  ,MAX(f.id_time) AS id_time
														  ,f.id_type
													   FROM 
														   dim_wag_initiative_media_type AS dwm
														   LEFT JOIN fact_outcome AS f
															   ON dwm.id_initiative = f.id_initiative
																 AND dwm.id_media_type = f.id_media_type
																 AND f.id_time <=
																			   (
																			    SELECT 
																				    id_dim_date
																			    FROM 
																				    dim_date
																			    WHERE year = @CURRENTYEAR
																					AND month = @CURRENTMONTH
																			   )
													   WHERE id_type IN (
																	1 -- maf
																    ,8)-- wag_adjustment)       
													   GROUP BY 
														   dwm.id
														  ,f.id_type--, d.month
													  ) AS f
												  ON f.id = dwm.id
											  LEFT JOIN #Dim_DateCurrentYear AS d
												  ON d.id_Dim_Date = f.id_time
										 ) AS mafwag
									 ON mafwag.id_initiative = f.id_initiative
									    AND mafwag.id_media_type = f.id_media_type
									    AND mafwag.id_time = f.id_time
									    AND mafwag.id_type = f.id_type
							) AS f
						ON f.id = dwm.id
				WHERE dwm.id_dim_date <= @ID_DIM_DATE
				UNION
				SELECT --bill register previous fiscal year 
					SUM(f.value)
				    ,14
				    ,f.id_initiative
				    ,f.id_media_type
				    ,14 AS id_type
				FROM 
					Fact_Outcome AS f
					JOIN #Dim_DatePreviousYear AS d
						ON d.id_Dim_Date = f.id_time
				WHERE id_type IN (
							  12
							 ,9)
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

			   


		  -- select to arrange info to send to excel
		SELECT 
			*
		FROM
			(
			 SELECT 
				 DENSE_RANK() OVER(
				 ORDER BY 
				 di.initiative_name) AS MAF#
				,dw.wag_forecast_initiative AS [WAG Forecast Initiative]
				,ISNULL(dw.lawson,'') AS Lawson
				,ISNULL(di.initiative_name,dw.wag_forecast_initiative + ' Auto Sum') AS Initiative
				,dm.media_type AS [Media Type]
				,dm.media_lawson AS [Media Lawson]
				,SUM(t2.MAF) AS [Annual MAF]
				,SUM(t2.WAG) AS [WAG Adjustments]
				,SUM(t2.PREVIOUSBILLREGISTER) AS PREVIOUSBILLREGISTER
				,SUM(CASE
						WHEN t2.SEPMRBR = 0  THEN t2.SEPMR
						ELSE t2.SEPMRBR
					END) AS [SEPT Mediacom Register]
				,SUM(t2.SEPMA) AS [SEPT WAG Actual]
				,SUM(CASE
						WHEN t2.OCTMRBR = 0 THEN t2.OCTMR
						ELSE t2.OCTMRBR
					END) AS [OCT Mediacom Register]
				,SUM(t2.OCTMA) AS [OCT WAG Actual]
				,SUM(CASE
						WHEN t2.NOVMRBR = 0 THEN t2.NOVMR
						ELSE t2.novmrbr
					END) AS [NOV Mediacom Register]
				,SUM(t2.NOVMA) AS [NOV WAG Actual]
				,SUM(CASE
						WHEN t2.DECMRBR = 0 THEN t2.DECMR
						ELSE t2.DECMRBR
					END) AS [DEC Mediacom Register]
				,SUM(t2.DECMA) AS [DEC WAG Actual]
				,SUM(CASE
						WHEN t2.JANMRBR = 0 THEN t2.JANMR
						ELSE t2.JANMRBR
					END) AS [JAN Mediacom Register]
				,SUM(t2.JANMA) AS [JAN WAG Actual]
				,SUM(CASE
						WHEN t2.FEBMRBR = 0 THEN t2.FEBMR
						ELSE t2.FEBMRBR
					END) AS [FEB Mediacom Register]
				,SUM(t2.FEBMA) AS [FEB WAG Actual]
				,SUM(CASE
						WHEN t2.MARMRBR = 0 THEN t2.MARMR
						ELSE t2.MARMRBR
					END) AS [MAR Mediacom Register]
				,SUM(t2.MARMA) AS [MAR WAG Actual]
				,SUM(CASE
						WHEN t2.APRMRBR = 0 THEN t2.APRMR
						ELSE t2.APRMRBR
					END) AS [APR Mediacom Register]
				,SUM(t2.APRMA) AS [APR WAG Actual]
				,SUM(CASE
						WHEN t2.MAYMRBR = 0 THEN t2.MAYMR
						ELSE t2.MAYMRBR
					END) AS [MAY Mediacom Register]
				,SUM(t2.MAYMA) AS [MAY WAG Actual]
				,SUM(CASE
						WHEN t2.JUNMRBR = 0 THEN t2.JUNMR
						ELSE t2.JUNMRBR
					END) AS [June Mediacom Register]
				,SUM(t2.JUNMA) AS [June WAG Actual]
				,SUM(CASE
						WHEN t2.JULMRBR = 0 THEN t2.JULMR
						ELSE t2.JULMRBR
					END) AS [July Mediacom Register]
				,SUM(t2.JULMA) AS [July WAG Actual]
				,SUM(CASE
						WHEN t2.AUGMRBR = 0 THEN t2.AUGMR
						ELSE t2.AUGMRBR
					END) AS [AUG Mediacom Register]
				,SUM(t2.AUGMA) AS [AUG WAG Actual]
			 FROM 
				 result_data AS t2
				 INNER JOIN dim_initiative AS di
					 ON di.id = t2.id_initiative
					    AND di.puerto_rico_initiative_yn = ISNULL(@puerto_rico_initiative_yn,di.puerto_rico_initiative_yn)
				 INNER JOIN dim_wag_forecast_initiative AS dw
					 ON dw.id = di.id_wag_forecast_initiative
				 INNER JOIN dim_media_type AS dm
					 ON dm.id = t2.id_media_type
					    AND dm.media_type = ISNULL(@media_type,dm.media_type)
			 GROUP BY 
				 GROUPING SETS((dw.wag_forecast_initiative,di.initiative_name,dw.lawson,dm.media_type,dm.media_lawson),(dw.
				 wag_forecast_initiative,dw.lawson,dm.media_type,dm.media_lawson))
			) AS RESULT
		WHERE CHARINDEX('ExtWag',Initiative) = 0
		ORDER BY 
			RESULT.initiative ASC
		    ,RESULT.[media type]
		    ,RESULT.[WAG Forecast Initiative]
END
