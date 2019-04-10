--	stored procedure name: usp_generate_initiative
--	description: usp that generates (insert/update) data of dim_initiative (where all the initiatives are located)
--	author: HVA
--	Date Creation: 20/11/2018
--	Date Modification: 01/01/2019 Include puerto rico field
--	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report

--	drop PROC usp_generate_initiative

CREATE PROC usp_generate_initiative (
	@ExecutionID BIGINT) 
AS
BEGIN

	MERGE dim_initiative AS target
	USING
		 (
		  SELECT DISTINCT 
			  dw.id
			 ,dw.wag_forecast_initiative
			 ,initiative
			 ,puerto_rico_initiative_yn
		  FROM 
			  STG_Master_Tracker_Match AS mtm
			  JOIN dim_wag_forecast_initiative AS dw
				  ON dw.wag_forecast_initiative = mtm.wag_forecast_initiative
		  WHERE mtm.wag_forecast_initiative != ''
		 ) AS source
		 ON target.initiative_name = source.initiative
		    AND target.id_wag_forecast_initiative = source.id
		WHEN MATCHED
		 THEN UPDATE SET 
		target.puerto_rico_initiative_yn = source.puerto_rico_initiative_yn
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		id_wag_forecast_initiative
	    ,initiative_name
	    ,puerto_rico_initiative_yn)
		 VALUES (
			   source.id
			  ,source.initiative
			  ,source.puerto_rico_initiative_yn);
	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'
	--******************************************************************************************************************************************************************************/
END
