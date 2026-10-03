// ImportRangeConnector - Apps Script web app that connects a spreadsheet to another spreadsheet for IMPORTRANGE,
// the same as clicking "Allow access" on the "You need to connect these spreadsheets" prompt.
//
// WSAdmin calls this after it writes a Tutor Details File ID into a Timesheet, so the Timesheet's
// IMPORTRANGE formula can read the Tutor Details spreadsheet without the prompt.
//
// The call is made from Apps Script because the docs.google.com endpoint it uses is undocumented and
// rejects WSAdmin's own access token. The web app is deployed to "Execute as: Me", so the request is made
// with the script owner's Apps Script token instead.
//
// Request (HTTP POST, JSON body):
//		{ "destinationFileID": "<Timesheet File ID>", "sourceFileID": "<Tutor Details File ID>" }
// Response (JSON):
//		{ "success": true/false, "statusCode": <HTTP status from docs.google.com>, "message": "<details>" }

// Google Drive File IDs are letters, digits, "-" and "_"
const FILE_ID_PATTERN = /^[A-Za-z0-9_-]{20,}$/;

// Web app entry point for HTTP POST requests from WSAdmin
function doPost(e) {
	let result;
	try {
		const params = JSON.parse(e.postData.contents);
		result = allowImportRange(params.destinationFileID, params.sourceFileID);
	} catch (error) {
		result = { success: false, statusCode: 0, message: "Bad request: " + error };
	}
	console.log(JSON.stringify(result));
	return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(ContentService.MimeType.JSON);
}

// Grants the destination spreadsheet permission to IMPORTRANGE from the source spreadsheet
//	Parameters:
//		destinationFileID: File ID of the spreadsheet containing the IMPORTRANGE formula (the Timesheet)
//		sourceFileID: File ID of the spreadsheet the IMPORTRANGE formula reads from (Tutor Details)
//	Returns:
//		{ success, statusCode, message }
function allowImportRange(destinationFileID, sourceFileID) {
	if (!FILE_ID_PATTERN.test(destinationFileID || "") || !FILE_ID_PATTERN.test(sourceFileID || "")) {
		return { success: false, statusCode: 0, message: "Invalid File ID - destination: " + destinationFileID + ", source: " + sourceFileID };
	}

	const url = "https://docs.google.com/spreadsheets/d/" + destinationFileID +
				"/externaldata/addimportrangepermissions?donorDoc=" + sourceFileID;
	const response = UrlFetchApp.fetch(url, {
		method: "post",
		headers: { Authorization: "Bearer " + ScriptApp.getOAuthToken() },
		muteHttpExceptions: true
	});

	const statusCode = response.getResponseCode();
	return {
		success: statusCode === 200,
		statusCode: statusCode,
		message: statusCode === 200 ? "Connected" : response.getContentText().substring(0, 500)
	};
}

// Run this from the Apps Script editor first (select it and click Run) to authorize the script and check that
// the call works.  Fill in the File IDs of a Timesheet and the Tutor Details spreadsheet it imports from;
// pick a Timesheet that currently shows the "You need to connect these spreadsheets" prompt.
function testAllowImportRange() {
	const destinationFileID = "PASTE_TIMESHEET_FILE_ID_HERE";
	const sourceFileID = "PASTE_TUTOR_DETAILS_FILE_ID_HERE";
	console.log(JSON.stringify(allowImportRange(destinationFileID, sourceFileID)));
}
