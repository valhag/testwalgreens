--	stored procedure name: usp_remove_execution
--	description: usp that allow to remove (update) the billable values contained on fact_outcome values, the idea is to update previous existing values, this values are saved on fact_outcome_history table
--	parameters: @filename, the name of the file we need to remove, as we can have process that generate or not rows on fact_outcome this process will take just the execution with status = success
--	author: HVA
--	Date Creation: 02/01/2019
--   Date Modification: 02/13/2019 remove previousdata, implement changes to suppor fact_outcome_history_table


--DROP PROC [dbo].[usp_remove_execution]
--select * from ExecutionLog
--exec usp_remove_execution 'FY19 MAF Tracker 201810.xlsx'

CREATE  PROC [dbo].[usp_remove_execution] (
	@filename VARCHAR(500)) 
AS
BEGIN
	BEGIN TRAN
	UPDATE Fact_Outcome
	SET 
		value = foh.value
	FROM Fact_Outcome f
		JOIN Fact_Outcome_history foh
			ON f.id_fact_outcome = foh.id_fact_outcome
	WHERE 
		foh.executionid IN
					    (
						SELECT 
							MAX(executionid)
						FROM 
							ExecutionLog
						WHERE FileName = @filename
							 AND STATUS = 'Success'
					    ) 
	

	UPDATE ExecutionLog
	SET 
		STATUS = 'Removed'
	WHERE 
		executionid IN
					(
					 SELECT 
						 MAX(executionid)
					 FROM 
						 ExecutionLog
					 WHERE FileName = @filename
						  AND STATUS = 'Success'
					) 


	COMMIT TRAN
	END