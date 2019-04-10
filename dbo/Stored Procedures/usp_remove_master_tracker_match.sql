-- drop PROC usp_remove_master_tracker_match
CREATE PROC usp_remove_master_tracker_match 
	@filename AS VARCHAR(200)
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

		DELETE FROM dim_wag_initiative_media_type
		WHERE 
			executionid = @executionid

		INSERT INTO dim_wag_initiative_media_type
		SELECT 
			id_media_type
		    ,id_initiative
		    ,id_dim_date
		    ,executionidprevious
		    ,fiscalyear
		FROM 
			dim_wag_initiative_media_type_history
		WHERE executionid = @executionid
			 AND executionid != executionidprevious

		DELETE FROM dim_wag_initiative_media_type_history
		WHERE 
			executionid = @executionid

		COMMIT TRANSACTION Removing
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRAN Removing
		END
	END CATCH
END