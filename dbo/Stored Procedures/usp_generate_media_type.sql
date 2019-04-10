--	stored procedure name: usp_generate_initiative
--	description: usp that generates (insert/update) data of dim_media_type (where all the media types are located)
--	author: HVA
--	Date Creation: 20/11/2018
--	Date Modification: 01/01/2019 Include puerto rico field
--	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report

--	drop PROC usp_generate_media_type

CREATE PROC usp_generate_media_type (
	@ExecutionID BIGINT) 
AS
BEGIN
	MERGE dim_media_type AS target
	USING
		 (
		  SELECT DISTINCT 
			  media_lawson_lawson_code_part_2
			 ,media_types
		  FROM 
			  STG_Master_Tracker_Match
		 ) AS source
	ON source.media_lawson_lawson_code_part_2 = target.media_lawson
	   AND source.media_types = target.media_type
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		media_lawson
	    ,media_type)
		 VALUES (
			   source.media_lawson_lawson_code_part_2
			  ,source.media_types);
	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'
	--******************************************************************************************************************************************************************************/
END

