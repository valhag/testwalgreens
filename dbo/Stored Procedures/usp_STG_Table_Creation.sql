/*
    drop PROC usp_STG_Table_Creation
    exec usp_STG_Table_Creation
*/

create PROC usp_STG_Table_Creation
AS
BEGIN
	IF OBJECT_ID('STG_maf_match') IS NOT NULL
		DROP TABLE STG_maf_match

	CREATE TABLE STG_maf_match
	(
		maf_initiative NVARCHAR(400) NOT NULL
		,master_tracker_initiative NVARCHAR(400) NOT NULL
		,filename nvarchar(500)
		,directory nvarchar(500)
	)


	IF OBJECT_ID('STG_writerdigital_match') IS NOT NULL
		DROP TABLE STG_writerdigital_match

	CREATE TABLE STG_writerdigital_match
	(
		row_number int
		,input_file NVARCHAR(400) NOT NULL
		,estimate NVARCHAR(400) NOT NULL
		,product NVARCHAR(400) NOT NULL
		,initiative NVARCHAR(400) NOT NULL
		,filename nvarchar(max)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_Writer_Digital') IS NOT NULL
		DROP TABLE STG_Writer_Digital
	CREATE TABLE STG_Writer_Digital
	(
		row_number				int
		,client					varchar(500)
		,gl_code				varchar(500)
		,media_type				varchar(500)
		,product_code			varchar(500)
		,estimate				varchar(500)
		,site					varchar(500)
		,month_of_service		varchar(500)
		,prisma_net_rate		varchar(500)
		,billed_to_the_client	varchar(500)
		,payable				varchar(500)
		,paid_to_the_site		varchar(500)
		,billable				varchar(500)
		,okay_to_pay_status		varchar(500)
		,filename nvarchar(max)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_TV_Writer') IS NOT NULL
		DROP TABLE STG_TV_Writer
	CREATE TABLE STG_TV_Writer
	(
		row_number				int
		,media				varchar(500)
		,product				varchar(500)
		,estimate				varchar(500)
		,month				varchar(500)
		,billable				varchar(500)
		,filename nvarchar(max)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_Writer_Print') IS NOT NULL
		DROP TABLE STG_Writer_Print
	CREATE TABLE STG_Writer_Print
	(
		row_number				int
		,client					varchar(500)
		,gl_code				varchar(500)
		,media_type				varchar(500)
		,product_code			varchar(500)
		,estimate				varchar(500)
		,month_of_service		varchar(500)
		,billable				varchar(500)
		,filename nvarchar(max)
		,directory nvarchar(500)
	)

	
	IF OBJECT_ID('STG_Writer_Radio') IS NOT NULL
		DROP TABLE STG_Writer_Radio
	CREATE TABLE STG_Writer_Radio
	(
		row_number				int
		,client					varchar(500)
		,gl_code				varchar(500)
		,media_type				varchar(500)
		,product_code			varchar(500)
		,estimate				varchar(500)
		,month_of_service		varchar(500)
		,billable				varchar(500)
		,filename nvarchar(max)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_Master_Tracker_Match') IS NOT NULL
		DROP TABLE STG_Master_Tracker_Match
	
	CREATE TABLE STG_Master_Tracker_Match
	(
		row_number int
		,initiative	nvarchar(500)
		,lawson	nvarchar(500)
		,media_lawson_lawson_code_part_2	nvarchar(500)
		,media_types	nvarchar(500)
		,puerto_rico_initiative_yn	nvarchar(500)
		,wag_forecast_initiative nvarchar(500)
		,filename nvarchar(max)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_MAF') IS NOT NULL
		DROP TABLE STG_MAF
	
	CREATE TABLE STG_MAF
	(
		row_number INT
		,client_code nvarchar(500)
		,lawson	nvarchar(500)
		,initiative nvarchar(500)
		,media_type nvarchar(500)
		,media_lawson nvarchar(500)
		,annual_maf_ nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_Programmatic') IS NOT NULL
		DROP TABLE STG_Programmatic
		
	
	CREATE TABLE STG_Programmatic
	(
		row_number INT
		,initiative nvarchar(500)
		,sepstring nvarchar(500)
		,octstring nvarchar(500)
		,novstring nvarchar(500)
		,decstring nvarchar(500)
		,janstring nvarchar(500)
		,febstring nvarchar(500)
		,marstring nvarchar(500)
		,aprstring nvarchar(500)
		,maystring nvarchar(500)
		,junstring nvarchar(500)
		,julstring nvarchar(500)
		,augstring nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_PuertoRico') IS NOT NULL
		DROP TABLE STG_PuertoRico
	CREATE TABLE STG_PuertoRico
	(
		row_number INT
		,initiative nvarchar(500)
		,media_type nvarchar(500)
		,lawson nvarchar(500)
		,media_lawson nvarchar(500)
		,sep nvarchar(500)
		,oct nvarchar(500)
		,nov nvarchar(500)
		,dec nvarchar(500)
		,jan nvarchar(500)
		,feb nvarchar(500)
		,mar nvarchar(500)
		,apr nvarchar(500)
		,may nvarchar(500)
		,jun nvarchar(500)
		,jul nvarchar(500)
		,aug nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_RadioWriter') IS NOT NULL
		DROP TABLE STG_PuertoRico
	
	CREATE TABLE STG_RadioWriter
	(
		row_number INT
		,client					varchar(500)
		,gl_code				varchar(500)
		,media					varchar(500)
		,product				varchar(500)
		,estimate				varchar(500)
		,site					varchar(500)
		,month_of_service		varchar(500)
		,prisma_net_rate		varchar(500)
		,billed_to_the_client	varchar(500)
		,payable				varchar(500)
		,paid_to_the_site		varchar(500)
		,billable				varchar(500)
		,okay_to_pay_status		varchar(500)
		,initiative nvarchar(500)
		,mos nvarchar(500)
		,value nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)


	IF OBJECT_ID('STG_SpotRadioWriter') IS NOT NULL
		DROP TABLE STG_SpotRadioWriter
	
	CREATE TABLE STG_SpotRadioWriter
	(
		row_number INT
		,client					varchar(500)
		,gl_code				varchar(500)
		,media					varchar(500)
		,product				varchar(500)
		,estimate				varchar(500)
		,month_of_service		varchar(500)
		,billable				varchar(500)
		,filename				nvarchar(500)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_SpotRadioWriter') IS NOT NULL
		DROP TABLE STG_NetworkWriter
	
	CREATE TABLE STG_NetworkWriter
	(
		row_number INT
		,media					varchar(500)
		,gl_code				varchar(500)
		,product				varchar(500)
		,estimate				varchar(500)
		,month_of_service		varchar(500)
		,billable				varchar(500)
		,filename				nvarchar(500)
		,directory nvarchar(500)
	)

	
	IF OBJECT_ID('STG_WAG_Forecast') IS NOT NULL
		DROP TABLE STG_WAG_Forecast
	
	CREATE TABLE STG_WAG_Forecast
	(
		row_number INT
		,initiative nvarchar(500)
		,Wag_Initiative_MediaType nvarchar(500)
		,sepstring nvarchar(500)
		,octstring nvarchar(500)
		,novstring nvarchar(500)
		,decstring nvarchar(500)
		,janstring nvarchar(500)
		,febstring nvarchar(500)
		,marstring nvarchar(500)
		,aprstring nvarchar(500)
		,maystring nvarchar(500)
		,junstring nvarchar(500)
		,julstring nvarchar(500)
		,augstring nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_External_WAG_Forecast') IS NOT NULL
		DROP TABLE STG_External_WAG_Forecast
	



	CREATE TABLE STG_External_WAG_Forecast
	(
		row_number INT
		,initiative nvarchar(500)
		,wag_initiative nvarchar(500)
		,sepstring nvarchar(500)
		,octstring nvarchar(500)
		,novstring nvarchar(500)
		,decstring nvarchar(500)
		,janstring nvarchar(500)
		,febstring nvarchar(500)
		,martring nvarchar(500)
		,aprstring nvarchar(500)
		,maystring nvarchar(500)
		,junstring nvarchar(500)
		,julstring nvarchar(500)
		,augstring nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)

	IF OBJECT_ID('STG_WAG_Adjustment') IS NOT NULL
		DROP TABLE STG_WAG_Adjustment


	CREATE TABLE STG_WAG_Adjustment
	(
		row_number INT
		,initiative nvarchar(500)
		,media_lawson_lawson_code_part_2 nvarchar(500)
		,wag_adjustment nvarchar(500)
		,filename nvarchar(500)
		,directory nvarchar(500)
	)

END