/* 
	stored procedure name: usp_generate_wag_initiative
	description: usp that generates (insert/update) data of dim_WAG_initiative (where all the WAG initiatives are located)
	author: HVA
	Date Creation: 20/11/2018
	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report

	drop PROC usp_generate_wag_initiative 

*/


CREATE PROC usp_generate_wag_initiative(
	@ExecutionID BIGINT)
AS
BEGIN
	MERGE dim_wag_forecast_initiative AS target
	USING
		 (
		  SELECT DISTINCT 
			  lawson
			 ,wag_forecast_initiative
		  FROM 
			  STG_Master_Tracker_Match
		 ) AS source
	ON target.lawson = source.lawson
	   AND target.wag_forecast_initiative = source.wag_forecast_initiative
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		lawson
	    ,wag_forecast_initiative)
		 VALUES (
			   source.lawson
			  ,source.wag_forecast_initiative);


	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'

END

