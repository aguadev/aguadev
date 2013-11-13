dojo.provide("plugins.core.Common.Text");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	DATE METHODS  
*/

dojo.declare( "plugins.core.Common.Text",	[  ], {

///////}}}

repeatChar : function(character, length) {
    var string = '';
    for ( var i = 0; i < length; i++ ) {
        string += character;
    }
    
    return string;
},
xor : function (option1, option2) {
	//console.log("  Common.Text.xor    plugins.core.Common.xor(option1, option2)");
	//console.log("  Common.Text.xor    option1: " + option1);
	//console.log("  Common.Text.xor    option2: " + option2);
	if ( (option1 && ! option2)
		|| (! option1 && option2) )	return true;
	return false;
},
systemVariables : function (value, object) {
// PARSE THE SYSTEM VARIABLES. I.E., REPLACE %<STRING>% TERMS
	if ( object == null )	object = this;
	if ( value == null || value == true || value == false )	return value;
	if ( value.replace == null )	return value;
	
	//console.log("  Common.Text.systemVariables    plugins.core.Common.systemVariables(value)");
	//console.log("  Common.Text.systemVariables    value: " + dojo.toJson(value));
	
	value = value.replace(/%username%/g, Agua.cookie('username'));
	value = value.replace(/%project%/g, object.project);
	value = value.replace(/%workflow%/g, object.workflow);
	
	return value;
},
insertTextBreaks : function (text, width) {
// INSERT INVISIBLE UNICODE CHARACTER &#8203; AT INTERVALS OF
// LENGTH width IN THE TEXT
	//console.log("  Common.Text.insertTextBreaks    plugins.workflow.Workflow.insertTextBreaks(text, width)");
	//console.log("  Common.Text.insertTextBreaks    text: " + text);	
	//console.log("  Common.Text.insertTextBreaks    text.length: " + text.length);	
	//console.log("  Common.Text.insertTextBreaks    width: " + width);

	if ( this.textBreakWidth != null )	width = this.textBreakWidth;
	if ( width == null )	return;

	// SET INSERT CHARACTERS
	var insert = "\n";

	// FIRST, REMOVE ANY EXISTING INVISIBLE LINE BREAKS IN THE TEXT
	text = this.removeTextBreaks(text);

	// SECOND, INSERT A "&#8203;" CHARACTER AT REGULAR INTERVALS
	var insertedText = '';
	var offset = 0;
	while ( offset < text.length )
	{
		var temp = text.substring(offset, offset + width);
		offset += width;
		
		insertedText += temp;
		//insertedText += "&#8203;"
		insertedText += insert;
	}

	//console.log("  Common.Text.insertTextBreaks    Returning insertedText: " + insertedText);
	return insertedText;
},
removeTextBreaks : function (text) {
// REMOVE ANY LINE BREAK CHARACTERS IN THE TEXT
	//console.log("  Common.removeTextBreaks    plugins.workflow.Common.removeTextBreaks(text)");
	//console.log("  Common.removeTextBreaks    text: " + text);	
	text = text.replace(/\n/g, '');
	return text;
},
jsonSafe : function (string, mode) {
// CONVERT FROM JSON SAFE TO ORDINARY TEXT OR THE REVERSE
	//console.log("ApplicationTemplate.jsonSafe string: " + string);
	//console.log("ApplicationTemplate.jsonSafe mode: " + mode);
	
	// SANITY CHECKS
	if ( string == null || ! string )
	{
		return '';
	}
	if ( string == true || string == false )
	{
		return string;
	}
	
	// CLEAN UP WHITESPACE
	string = String(string).replace(/\s+$/g,'');
	string = String(string).replace(/^\s+/g,'');
	string = String(string).replace(/"/g,"'");

	var specialChars = [
		[ '&quot;',	"'" ],	
		//[ '&quot;',	'"' ],	
		[ '&#35;', '#' ],	
		[ '&#36;', '$' ],	
		[ '&#37;', '%' ],	
		[ '&amp;', '&' ],	
		//[ '&#39;', "'" ],	
		[ '&#40;', '(' ],	
		[ '&#41;', ')' ],	
		[ '&frasl;', '/' ],	
		[ '&#91;', '\[' ],	
		[ '&#92;', '\\' ],	
		[ '&#93;', '\]' ],	
		[ '&#96;', '`' ],	
		[ '&#123;', '\{' ],	
		[ '&#124;', '|' ],	
		[ '&#125;', '\}' ]	
	];
	
	for ( var i = 0; i < specialChars.length; i++)
	{
		if ( mode == 'toJson' )
		{
			var sRegExInput = new RegExp(specialChars[i][1], "g");
			return string.replace(sRegExInput, specialChars[i][0]);
		}
		else if ( mode == 'fromJson' )
		{
			var sRegExInput = new RegExp(specialChars[i][0], "g");
			return string.replace(sRegExInput, specialChars[i][1]);
		}
	}
	
	return string;
},
autoHeight : function(textarea) {
	//console.log("  Common.Text.autoHeight    plugins.workflow.Workflow.autoHeight(event)");
	//console.log("  Common.Text.autoHeight    textarea: " + textarea);

	var rows = parseInt(textarea.rows);
	console.log("  Common.Text.autoHeight    textarea.rows: " + textarea.rows);

	while ( textarea.rows * textarea.cols < textarea.value.length )
	{
		textarea.rows = ++rows;
	}
	
	// REMOVE ONE LINE TO FIT SNUGLY
	//textarea.rows--; 
	
////    // THIS ALSO WORKS OKAY
////    console.log("  Common.Text.autoHeight    event.target.scrollHeight: " + event.target.scrollHeight );
////    
////    var height = event.target.scrollHeight;
////    var rows = parseInt((height / 15) - 2);
////
////    console.log("  Common.Text.autoHeight    height: " + height);
////    console.log("  Common.Text.autoHeight    rows: " + rows);
////
//////<textarea id="value" class="autosize" rows="3" cols="10">    
////    
////    console.log("  Common.Text.autoHeight    BEFORE event.target.setAttribute('rows', " + rows + "): " +  event.target.getAttribute('rows'));
////    
////    event.target.setAttribute('rows', rows);
////    
////
////    console.log("  Common.Text.autoHeight    AFTER event.target.setAttribute('rows', " + rows + "): " + event.target.getAttribute('rows'));}
},
firstLetterUpperCase : function (word) {
	if ( word == null || word == '' ) return word;
	if ( word.substring == null )	return null;
	return word.substring(0,1).toUpperCase() + word.substring(1);
},
cleanEnds : function (words) {
	if ( words == null )	return '';

	words = words.replace(/^[\s\n]+/, '');
	words = words.replace(/[\s\n]+$/, '');
	
	return words;
},
cleanWord : function (word) {
	//console.log("  Common.cleanWord    plugins.core.Common.cleanWord(word)");
	//console.log("  Common.cleanWord    word: " + word);

	if ( word == null )	return '';

	return word.replace(/[\s\n]+/, '');
},
clearValue : function (widget, value) {
	//console.log("  Common.clearValue    plugins.core.Common.clearValue(widget, value)");
	//console.log("  Common.clearValue    widget: " + widget);
	//console.log("  Common.clearValue    value: " + value);
	if ( widget == null )	return;

	if ( widget.get && widget.get('value') == value )
	{
		widget.set('value', '');
	}
	else if ( widget.value && widget.value.match(value) )
	{
		widget.value = '';
	}
},
cleanNumber : function (number) {
	//console.log("  Common.cleanNumber    plugins.core.Common.cleanNumber(number)");
	////console.log("Clusters.cleanNumber    BEFORE number: " + number);
	if ( number == null )	return '';
	number = number.toString().replace(/[\s\n]+/, '');
	////console.log("Clusters.cleanNumber    AFTER number: " + number);

	return number.toString().replace(/[\s\n]+/, '');
},
convertString : function (string, type) {
	if ( string == null )	return '';
	//console.log("  Common.Text.convertString    plugins.form.EditForm.convertString(string)");
	//console.log("  Common.Text.convertString    type: " + type);
	//console.log("  Common.Text.convertString    string: " + dojo.toJson(string));

	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;

	var before = string;
	string = this.convertAngleBrackets(string, type);
	string = this.convertAmpersand(string, type);
	string = this.convertQuote(string, type);

	//console.log("  Common.Text.convertString    converted " + dojo.toJson(before) + " to " + dojo.toJson(string));
	
	return string
},
convertBackslash : function (string, type) {
	//console.log("  Common.Text.convertBackslash    plugins.core.Common.convertBackslash(string, type)");	
//    console.log("  Common.Text.convertBackslash    string:" + dojo.toJson(string));
//	console.log("  Common.Text.convertBackslash    type: " + type);
	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	
	try {
		
		var multiplyString = function (string, num) {
			if (!num) return "";
			var newString = string;
			while (--num) newString += string;
			return newString;
		};
	
		var compress = function(match) {
			return multiplyString("\\", (match.length / 2));
		};
		
		var expand = function(match) {
			return multiplyString("\\", (match.length * 2));
		};
	
		if ( type == "compress" ) { 
			string = string.replace(/\\+/g, compress);
		}
		if ( type == "expand" ) { 
			string = string.replace(/\\+/g, expand);
		}
		//console.log("  Common.Text.convertBackslash    returning string:" + dojo.toJson(string));
		
	}
	catch (error) {
		//console.log("  Common.Text.convertBackslash    error:" + error);
		return "";
	}	
	
    return string;
},
convertAmpersand : function (string, type) {
	//console.log("  Common.Text.convertAmpersand    plugins.form.EditForm.convertAmpersand(string)");
	//console.log("  Common.Text.convertAmpersand    string: " + string);
	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	if ( type == "textToHtml")
		string = string.replace(/&/g, "&amp;");
	else
		string = string.replace(/&amp;/g, "&");
	return string;
},
convertQuote : function (string, type) {
	//console.log("  Common.Text.convertQuote    plugins.form.EditForm.convertQuote(string)");
	//console.log("  Common.Text.convertQuote    string: " + string);
	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	if ( type == "textToHtml")
		string = string.replace(/"/g, "&quot;");
	else
		string = string.replace(/&quot;/g, '"');
	return string;
},
convertAngleBrackets : function (string, type) {
	//console.log("  Common.Text.convertAngleBrackets    plugins.form.EditForm.convertAngleBrackets(string)");
	//console.log("  Common.Text.convertAngleBrackets    string: " + string);

	if ( string == null ) 	return '';
	if ( string.replace == null )	return string;
	
	var specialChars = [
		[ '&lt;',	"<" ],
		[ '&gt;',	'>' ]
	];

	var from = 0;
	var to = 1;
	if ( type == "textToHtml")
	{
		from = 1;
		to = 0;
	}
	
	for ( var i = 0; i < specialChars.length; i++)
	{
		////console.log("  Common.Text.converString    converting from " +specialChars[i][from] + " to " + specialChars[i][to]);
		var sRegExInput = new RegExp(specialChars[i][from], "g");
		string = string.replace(sRegExInput, specialChars[i][to]);
	}

	return string;	
},
printObjectKeys : function (hasharray, key, label) {
	if ( label == null )	label = "key";
	for ( var i = 0; i < hasharray.length; i++ )
	{
		console.log(label + " " + i + ": " + hasharray[i][key]);
	}
},


});