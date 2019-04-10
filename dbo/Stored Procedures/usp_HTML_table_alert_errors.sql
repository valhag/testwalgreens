
CREATE PROC [dbo].[usp_HTML_table_alert_errors] (
	@FileName VARCHAR(1000)
    ,@ExecutionID BIGINT
    ,@MailBody VARCHAR(MAX) OUT) 
AS
	BEGIN
--*****************************************************************************************************************************************/

--****************************************************** TEST VARIABLES ********************************************************************
--DECLARE  @MailBody VARCHAR(MAX), @ExecutionID BIGINT, @FileName VARCHAR(100)
--SET @ExecutionID=19
--SET @FileName='Test'
----*****************************************************************************************************************************************

--*************************************** DECLARE VARIABLES  ******************************************************************************

		DECLARE @ErrorCount INT
		SET @ErrorCount = 0
--******************************************************************************************************************************************/

--*************************************** HTML HEADS & CSS ********************************************************************************

		SET @MailBody = '<html> <body> <style>
						
						table, th, td {
						border: 1px solid black;
						border-collapse: collapse;
						text-align: center;
						vertical-align: middle;			
						font-family: "Tahoma", "Geneva", sans-serif;	
						padding: 5px;			
						}

						tr:nth-child(even) {background-color: #f2f2f2;}
						th {
						   background-color: #bacbf8;						   
						   }
				   </style>
				   <br/>
				   <br/>
				   The following errors were found while attempting to process your file. The file has not been processed.  Once you have resolved the errors, please re-upload the file for processing.  This table can be copied into Excel for sorting.
				   <br/>
				   <br/>
				   <table>				   
				   <tr>
				   <th>File Name</th>
				   <th>Row Number</th>
				   <th>Message</th>
				   <th>TimeStamp</th></tr>
				   '
--*******************************************************************************************************************************************/

--**************************** ASSIGN DYNAMIC QUERY WITH HTML TABLE COLUMNS ***************************************************************

		SELECT 
			@MailBody = @MailBody+'<tr><td>'+filename+'</td><td>'+ISNULL(CAST(row AS VARCHAR(10)),'')+'</td><td>'+message+'</td><td>'+CAST(
			TimeStamp AS VARCHAR(50))+'</td></tr>'
		FROM 
			Errors
		WHERE ExecutionID = @ExecutionID
		ORDER BY convert(int,row)
--*******************************************************************************************************************************************/

--********************************* GETTING FINAL QUERY WITH HTML FORMAT *********************************************************************

		SET @ErrorCount =
					   (
					    SELECT 
						    COUNT(*)
					    FROM 
						    Errors
					    WHERE ExecutionID = @ExecutionID
					   )
--**********************************************************************************************************************************************/

--************************************** ADDING QUERY RESULT TO MAILBODY **********************************************************************    

		SET @MailBody = @MailBody+'</table>'
		SET @MailBody = @MailBody+'</br><h3>There are '+ISNULL(CAST(@ErrorCount AS VARCHAR(100)),0)+' errors on file: '+@FileName+'</h3></html>'


		RETURN 
--**********************************************************************************************************************************************/
	END
