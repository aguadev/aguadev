console.log("plugins.request.Search    LOADING");

/* SUMMARY: ALLOW USER TO SEARCH GENOMIC FILES IN GNOS REPOSITORIES USING METADATA TERMS */

define("plugins/request/Search", [
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dojo/dom-construct",
	"dojo/Deferred",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/_WidgetsInTemplateMixin",
	"plugins/core/Common",
	"plugins/request/SimpleSearch",
	"plugins/request/Query",
	"plugins/request/Saved",
	"plugins/request/Downloads",
	
	// STORE	
	"dojo/store/Memory",
	
	// STATUS
	"plugins/form/Status",
	
	// STANDBY
	"dojox/widget/Standby",
	
	// DIALOGS
	"plugins/dijit/ConfirmDialog",
	"plugins/dijit/SelectiveDialog",
	
	// WIDGETS IN TEMPLATE
	"dijit/form/SimpleTextarea",
	"dijit/layout/ContentPane",
	"dijit/form/ComboBox",
	"dijit/form/Button"
],

function (
	declare,
	arrayUtil,
	JSON,
	on,
	lang,
	domAttr,
	domClass,
	domConstruct,
	Deferred,
	_Widget,
	_TemplatedMixin,
	_WidgetsInTemplateMixin,
	Common,
	SimpleSearch,
	Query,
	Saved,
	Downloads,
	Memory,
	Status,
	Standby,
	ConfirmDialog,
	SelectiveDialog,
	ContentPane
) {

/////}}}}}

return declare("plugins/request/Search",
	[ _Widget, _TemplatedMixin, _WidgetsInTemplateMixin, Common ], {

// templateString : String	
// 		Template of this widget
templateString: dojo.cache("plugins", "request/templates/search.html"),

// cssFiles: Array
// CSS FILES
cssFiles : [
	require.toUrl("plugins/request/css/search.css")
],

// url : String
// 		URL of remote GNOS instance
url: null,

// core : HashRef
//		Hash of core classes
core : {},

// fields : ArrayRef
//		Array of field options
fields : null,

// fieldOperators : HashRef
//		Hash of fields against operators
fieldOperators : null,

// fieldTypes : HashRef
//		Hash of fields against input types
fieldTypes : null,

////}}}
constructor : function(args) {	
	console.log("Search.constructor    args:");
	console.dir({args:args});

	// MIXIN ARGS
	lang.mixin(this, args);
	
	console.log("Search.constructor    this.baseUrl: " + this.baseUrl);
	
	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "/agua.cgi";
	
	// LOAD CSS FILES
	this.loadCSS(this.cssFiles);		
},
postCreate: function() {
	this.startup();
},
// STARTUP
startup : function () {
	console.group("Search-" + this.id + "    startup");
	console.log("-------------------------- Search.startup    this.browsers:");
	console.log("Search.startup    this.loadOnStartup: " + this.loadOnStartup);

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	// ADD THE PANE TO THE TAB CONTAINER
	this.attachPane();
	
	//// SET LISTENERS
	//this.setListeners();
	
	// SET QUERY
	this.setSimpleSearch();

	// SET QUERY
	this.setQuery();

	// SET SAVED
	this.setSaved();

	// SET SAVED
	this.setDownloads();
},
// SETTERS
setQuery : function () {
	console.log("Search.setQuery    ");
	
	this.core.query = new Query({
		parent : this,
		attachPoint : this.queryAttachPoint,
		url 			: 	this.url,
		core 			: 	this.core,
		fields			:	this.fields,
		fieldOperators	:	this.fieldOperators,
		fieldTypes		:	this.fieldTypes
	});
},
setSimpleSearch : function () {
	console.log("Search.setSimpleSearch    ");
	
	this.core.simpleSearch = new SimpleSearch({
		parent : this,
		attachPoint : this.searchAttachPoint,
		url : this.url,
		core: this.core
	});
},
setSaved : function () {
	console.log("Search.setSaved");
	
	this.core.saved = new Saved({
		parent : this,
		attachPoint : this.savedAttachPoint,
		url : this.url,
		core : this.core
	});
},
setDownloads : function () {
	console.log("Search.setDownloads");
	
	this.core.downloads = new Downloads({
		parent : this,
		attachPoint : this.downloadsAttachPoint,
		url : this.url,
		core : this.core
	});
},
attachPane : function () {
	console.log("Search.attachPane    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
	console.log("Search.attachPane    this.containerNode: " + this.containerNode);
	console.dir({this_containerNode:this.containerNode});
	
	if ( this.attachPoint.selectChild ) {
		console.log("Search.attachPane    DOING this.addchild(this.containerNode)");
		this.attachPoint.addChild(this.containerNode);
		this.attachPoint.selectChild(this.containerNode);
	}
	else {
		console.log("Search.attachPane    DOING this.appendchild(this.containerNode)");
		this.attachPoint.appendChild(this.containerNode);
	}
},

//    var allSelectedFiles2 = [];
//
//
//        var now = new Date();
//        now.format("dd/M/yy h:mm:ss");
//        $('#txtDName').val("andyh " + now.format("dd/M/yy h:mm:ss"));
//        //GetAllChecked();
//        $("#btnDownload23").click(function () {
//            /*var ids = [];
//            var rows = $('#ResultsTable').datagrid('getSelections');
//            for (var i = 0; i < rows.length; i++) {
//            ids.push(rows[i].itemid);
//            }
//            alert(ids.join('\n'));*/
//            //$("input:checkbox[name:contains '_CheckBox']:checked").each(function () {
//            GetAllSelectedFiles2(); //$(this).closest("tr"));
//            //});
//
//            var gtaUUID = $("option:selected", ".GTA").val();
//            var requestName = $(".RequestName").val();
//            //var selectedObjects = allSelectedFiles;
//            var selectedObjects2 = allSelectedFiles2
//            var totalSize = 0;
//            var confirmationMessage = "";
//            var confirmed = false;
//            var selectedFilesLive = true;
//
//            if (gtaUUID === undefined) {
//                confirmationMessage += "There is no GT agent selected. Please select a GT agent.";
//                confirmed = false;
//
//            }
//            else if (requestName.length == 0) {
//                confirmationMessage += "Please enter a name for the download.";
//                confirmed = false;
//            }
//            else {
//                for (i = 0; i < selectedObjects2.length; i++) {
//                    totalSize += CalculateFileSizeInBytes(selectedObjects2[i].FileSize);
//                    var state = selectedObjects2[i].State;
//                    state = state.substr(0, 4);
//                    if (state != 'live') {
//                        selectedFilesLive = false;
//                        confirmationMessage = "Your download request contains Analysis Objects where the State is not 'live' and are not downloadable.  Please change your selection to only include objects with a 'live' State.";
//                        confirmed = false;
//                    }
//                }
//                if (selectedObjects2.length == 0 && selectedFilesLive == true) {
//                    confirmationMessage += "Please select at least one item for download.";
//                    confirmed = false;
//                }
//                if (selectedObjects2.length > 0 && selectedObjects2.length <= 500 && selectedFilesLive == true) {
//                    confirmationMessage += "You have selected " + selectedObjects2.length + " item(s) for a total download size of " + GetFileSizeInUnit(totalSize) + ".\n";
//                    confirmationMessage += "The item(s) will be tracked as a single download request named '" + requestName + "'.\n\n";
//                    confirmationMessage += "Click 'Ok' to proceed.";
//                    confirmed = true;
//                }
//                if (selectedObjects2.length > 500 && selectedFilesLive == true) {
//                    confirmationMessage += "You have selected more than 500 items to download.  Please refine your selection.";
//                    confirmed = false;
//                }
//            }
//            if (confirmed != true) {
//                alert(confirmationMessage);
//            }
//            else {
//                input_box = confirm(confirmationMessage);
//                if (input_box == true) {
//                    // Output when OK is clicked
//                    SaveTransaction(selectedObjects2, gtaUUID, requestName);
//                }
//            }
//            //reset cookie
//            resetCookie();
//        });
//    });

//    function resetCookie() {
//        //remove Cookie
//        $.removeCookie("itemSelection");
//        //reset Array
//        allSelectedFiles2 = [];
//        //uncheck selection
//        uncheckSelection();
//        //hide notification
//        $(".download-notice").css("display", "none");
//        var now = new Date();
//        now.format("dd/M/yy h:mm:ss");
//        $('#txtDName').val("andyh " + now.format("dd/M/yy h:mm:ss"));
//
//    }
//    function uncheckSelection() {
//        $('.srch-CheckBox').find('input').each(function () {
//            //if ($(this).attr('value') == dEntry[0])
//            $(this).attr('checked', false);
//        });
//        $("#lblObjects").text("0 Objects");
//        $("#lblSize").text("0 Bytes");
//        document.getElementById('DLEnable').style.display = "none";
//        document.getElementById('DLDisable').style.display = "inline";
//    }
//    function enableCheckBoxes() {
//        var cEntries = $.cookie("itemSelection").split('$');
//        for (var i = 0; i < cEntries.length - 1; i++) {
//            var dEntry = cEntries[i].split(',');
//            $('.srch-CheckBox').find('input').each(function () {
//                if ($(this).attr('value') == dEntry[0])
//                    $(this).attr('checked', true);
//            });
//        }
//    }
//    function showNotice() {
//        if ($.cookie("itemSelection") != null) {
//            if ($.cookie("itemSelection") != "") {
//                var totalSize = 0;
//                var cEntries = $.cookie("itemSelection").split('$');
//                for (var i = 0; i < cEntries.length - 1; i++) {
//                    var dEntry = cEntries[i].split(',');
//                    totalSize += CalculateFileSizeInBytes(dEntry[2]); //parseInt([1].substring(0,dEntry[1].indexOf(' ')));
//                }
//                var sObj;
//                if (cEntries.length - 1 == 1)
//                    sObj = "1 Object";
//                else
//                    sObj = (cEntries.length - 1) + " Objects";
//                $("#lblObjects").text(sObj);
//                $("#lblSize").text(GetFileSizeInUnit(totalSize));
//                var notice = "You have selected " + (cEntries.length - 1) + " item(s) for a total download size of " + GetFileSizeInUnit(totalSize) + ".\n" +
//                    "The item(s) will be tracked as a single download request named '" + $(".RequestName").val() + "'.\n\n";
//                document.getElementById('DLEnable').style.display = "inline";
//                document.getElementById('DLDisable').style.display = "none";
//            }
//            else {
//                $(".download-notice").css("display", "none");
//                $(".download-notice").find("p").html("");
//                $("#lblObjects").text("0 Objects");
//                $("#lblSize").text("0 Bytes");
//                document.getElementById('DLEnable').style.display = "none";
//                document.getElementById('DLDisable').style.display = "inline";
//            }
//        }
//        else {
//            $(".download-notice").css("display", "none");
//            $("#lblObjects").text("0 Objects");
//            $("#lblSize").text("0 Bytes");
//            document.getElementById('DLEnable').style.display = "none";
//            document.getElementById('DLDisable').style.display = "inline";
//        }
//    }
//    function toggleCheckbox(chk) {
//        //var hid = document.getElementById('" + hfChecked.ClientID + "');
//        var tr = chk.parentNode.parentNode;
//        var posSourcURI = $('.ms-unselectedtitle:contains("Analysis URI")').parent().index();
//        var posFileSize = $('.ms-unselectedtitle:contains("File Size")').parent().index();
//        var posState = $('.ms-unselectedtitle:contains("State")').parent().index();
//        if (tr.getElementsByTagName('td')[posState].innerHTML != 'live') {
//            chk.checked = !chk.checked;
//        }
//        else {
//            if (chk.checked) {
//                if ($.cookie("itemSelection") != null) {
//                    var SourceURI = tr.getElementsByTagName('td')[posSourcURI].innerHTML;
//                    var FileSize = GetFileSizeInUnit2(tr.getElementsByTagName('td')[posFileSize].innerHTML);
//                    var State = tr.getElementsByTagName('td')[posState].innerHTML;
//
//                    var oldVal = $.cookie("itemSelection");
//                    $.cookie("itemSelection", oldVal + chk.value + "," + SourceURI + "," + FileSize + "," + State + "$");
//                }
//                else {
//                    $.removeCookie("itemSelection");
//                    var SourceURI = tr.getElementsByTagName('td')[posSourcURI].innerHTML;
//                    var FileSize = GetFileSizeInUnit2(tr.getElementsByTagName('td')[posFileSize].innerHTML);
//                    var State = tr.getElementsByTagName('td')[posState].innerHTML;
//
//
//                    $.cookie("itemSelection", chk.value + "," + SourceURI + "," + FileSize + "," + State + "$");
//                }
//                showNotice();
//            }
//            else {
//                if ($.cookie("itemSelection") != null) {
//                    var SourceURI = tr.getElementsByTagName('td')[posSourcURI].innerText;
//                    var FileSize = GetFileSizeInUnit2(tr.getElementsByTagName('td')[posFileSize].innerText);
//                    var State = tr.getElementsByTagName('td')[posState].innerText;
//
//                    var oldVal = $.cookie("itemSelection");
//                    var newVal = oldVal.replace(chk.value + "," + SourceURI + "," + FileSize + "," + State + "$", "");
//                    $.cookie("itemSelection", newVal);
//                    if ($.cookie("itemSelection").length == 0)
//                        $.removeCookie("itemSelection");
//                    showNotice();
//                }
//            }
//        }
//        //sb.Append("             hid.value += chk.value+','+tr.getElementsByTagName('td')[11].innerText+','+tr.getElementsByTagName('td')[14].innerText+','+tr.getElementsByTagName('td')[9].innerHTML+'$';\n");
//    }
//
//    function GetAllSelectedFiles2() {//dataContainer) {
//        //var data = dataContainer.find("td"); //, dataContainer);
//        //var posSourcURI = $('.ms-unselectedtitle:contains("Analysis URI")').parent().index();
//        //var posFileSize = $('.ms-unselectedtitle:contains("File Size")').parent().index();
//        //var posState = $('.ms-unselectedtitle:contains("State")').parent().index();
//        //alert(data.html());
//        if ($.cookie("itemSelection") != null) {
//            var cEntries = $.cookie("itemSelection").split('$');
//            for (var i = 0; i < cEntries.length - 1; i++) {
//                var dEntry = cEntries[i].split(',');
//                var bamFile = {
//                    SourceURI: dEntry[1],
//                    FileSize: dEntry[2],
//                    State: dEntry[3]
//                }
//                //alert(bamFile[1]);
//                allSelectedFiles2.push(bamFile);
//            }
//        }
//        else
//            allSelectedFiles2 = [];
//
//    }



//SelectAllCheckBoxes: function() { 
//	var checkboxes = document.getElementsByTagName('input'); 
//	for(var i=0; i<checkboxes.length; i++) 
//	{ 
//	   // Look for a CheckBox 
//	   var checkbox = checkboxes[i]; 
//	   
//	   // Verify it's the right name 
//	   var end = '_CheckBox'; 
//	   var endsWith = checkbox.id.match(end+'$')==end; 
//	   
//	   // Make the switch 
//	   if(endsWith) 
//	   { 
//		  if(isSelected) 
//		  { 
//			//Deselects the check boxes 
//			checkbox.checked = false; 
//		  } 
//		  else 
//		  { 
//			//Selects all the check boxes 
//		   var tr = checkbox.parentNode.parentNode;
//		   if(tr.getElementsByTagName('td')[9].innerHTML != 'suppressed')
//			{checkbox.checked = true;} 
//		  } 
//	   } 
//	} 
//	this.isSelected = ! this.isSelected; 
//} 

//GetAllChecked : function () { 
//	var hid = document.getElementById('ctl00_m_g_f61132e1_3ba4_4768_981d_1278ee9020bf_ctl01');
//	var checkboxes = document.getElementsByTagName('input'); 
//	for(var i=0; i<checkboxes.length; i++) 
//	{ 
//	   // Look for a CheckBox 
//	   var checkbox = checkboxes[i]; 
//	   
//	   // Verify it's the right name 
//	   var end = '_CheckBox'; 
//	   var endsWith = checkbox.id.match(end+'$')==end; 
//	   
//	   // Make the switch 
//	   if(endsWith) 
//	   { 
//		  if(checkbox.checked) 
//		  { 
//			hid.value += checkbox.value + ', '; 
//		  } 
//	   } 
//	} 
//	} 
//

}); //	end declare

});	//	end define

console.log("plugins.request.Search    END");
