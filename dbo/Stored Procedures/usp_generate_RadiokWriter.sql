--	stored procedure name: usp_generate_RadiokWriter
--	description: usp that generates (insert/update) data of fact_outcome for RADIO WRITER file type
--	parameters: @executionID just to report success on validation/generation
--	author: HVA
--	Date Creation: 20/11/2018
--	Date Modification: 01/23/2019 change STG_writerdigital_match to dim_writer_match
--	Date Modification: 24/01/2019 include id_time_generated
--  Date Modification: 28/01/2019 include just valid initiatives-media types 

--	drop PROC usp_generate_RadiokWriter


CREATE PROC dbo.usp_generate_RadiokWriter (
	@ExecutionID BIGINT
    ,@CURRENTYEAR AS INT
    ,@CURRENTMONTH AS INT) 
AS
BEGIN



	MERGE dbo.Fact_Outcome AS TARGET
	USING
		 (
		  SELECT 
			  di.id AS id_initiative
			 ,dmt.id AS id_media_Type
			 ,SUM(CAST(snwr.billable AS MONEY)) AS value
			 ,dd.id_Dim_Date
			 ,7 AS id_type
			 ,
			   (
			    SELECT 
				    id_Dim_Date
			    FROM 
				    dim_date
			    WHERE year = @CURRENTYEAR
					AND month = @CURRENTMONTH
			   ) AS id_time_generated
		  FROM 
			  dbo.STG_Writer_Radio AS snwr
			  INNER JOIN dbo.dim_writer_match AS wdm
				  ON snwr.estimate = wdm.estimate
					AND wdm.input_file = 'Radio Writer'
			  INNER JOIN dbo.dim_initiative AS di
				  ON di.initiative_name = wdm.initiative
			  INNER JOIN dbo.dim_media_type AS dmt
				  ON dmt.media_lawson = RIGHT(snwr.gl_code,6)
			  JOIN dim_wag_initiative_media_type AS dwi
				  ON dwi.id_initiative = di.id
					AND dwi.id_media_type = dmt.id
					AND dwi.id_dim_date <=
									   (
									    SELECT 
										    id_dim_date
									    FROM 
										    dim_date
									    WHERE year = @CURRENTYEAR
											AND month = @CURRENTMONTH
									   ) 
			  INNER JOIN dbo.month_names AS mn
				  ON mn.month_name = LEFT(snwr.month_of_service,3)
			  INNER JOIN dbo.Dim_Date AS dd
				  ON dd.year = CONVERT(INT,'20' + RIGHT(snwr.month_of_service,2))
					AND dd.month = mn.id
					AND LTRIM(RTRIM(STR(dd.year))) + RTRIM(LTRIM(replace(STR(dd.month,2),SPACE(1),'0'))) > LTRIM(RTRIM(STR(@CURRENTYEAR))) +
					RTRIM(LTRIM(replace(STR(@CURRENTMONTH,2),SPACE(1),'0')))
		  GROUP BY 
			  di.id
			 ,dmt.id
			 ,mn.id
			 ,dd.id_Dim_Date
		 ) AS SOURCE
		 ON SOURCE.id_initiative = TARGET.id_initiative
		    AND SOURCE.id_media_type = TARGET.id_media_type
		    AND SOURCE.id_type = TARGET.id_type
		    AND SOURCE.id_Dim_Date = TARGET.id_time
		    AND SOURCE.id_time_generated = TARGET.id_time_generated
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		id_initiative
	    ,id_media_type
	    ,value
	    ,id_time
	    ,id_type
	    ,id_time_generated)
		 VALUES (
			   SOURCE.id_initiative
			  ,SOURCE.id_media_type
			  ,SOURCE.value
			  ,SOURCE.id_dim_date
			  ,SOURCE.id_type
			  ,SOURCE.id_time_generated) 
		WHEN MATCHED
		 THEN UPDATE SET 
		target.value = source.value;

	--********************************************** UPDATE SUCCESS EXECUTION LOG *************************************************************************************************

	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'
	--******************************************************************************************************************************************************************************/

END
--******************************************************   END SP usp_Table_Creation *******************************************************************************************/
