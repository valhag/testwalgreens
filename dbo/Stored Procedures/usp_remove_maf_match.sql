--DROP proc usp_remove_maf_match

CREATE PROC usp_remove_maf_match 
	@filename AS VARCHAR(100)
AS
BEGIN
	DECLARE @executionid INT
	SELECT 
		@executionid = MAX(executionid)
	FROM 
		ExecutionLog
	WHERE FileName = @filename
		 AND STATUS = 'Success'
	BEGIN TRY
		BEGIN TRAN Removing

		DELETE FROM dim_maf_match
		WHERE 
			executionid = @ExecutionID

		INSERT INTO dim_maf_match(
			maf_initiative
		    ,master_tracker_initiative
		    ,id_dim_date
		    ,executionid)
		SELECT 
			maf_initiative
		    ,master_tracker_initiative
		    ,id_dim_date
		    ,executionidprevious
		FROM 
			dim_maf_match_history
		WHERE executionid = @ExecutionID
			 AND executionid != executionidprevious

		DELETE FROM dim_maf_match_history
		WHERE 
			executionid = @ExecutionID

		COMMIT TRANSACTION Removing
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRAN Removing
		END
	END CATCH
END