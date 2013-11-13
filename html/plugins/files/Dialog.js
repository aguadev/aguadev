dojo.provide("plugins.files.Dialog");

// DISPLAY A LOGIN DIALOGUE WINDOW AND AUTHENTICATE
// WITH THE SERVER TO RETRIEVE A SESSION ID WHICH IS
// STORED AS Agua.cookie("sessionid")

dojo.require("dojox.widget.Dialog");
dojo.require("dojo.fx.easing");
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
//dojo.require("Agua.cookie"); 
dojo.require("dojox.timing.Sequence");

dojo.declare( "plugins.files.Dialog",
	[ plugins.core.Common ],
{
	loginMessageId: "loginMessage",

	loginLauncherId: "loginLauncher",

	message : '',
	
	parentFunction : null,
	
	args: null,
	
	dialogWidget: null,

	cssFiles: [
		dojo.moduleUrl("plugins", "files/css/dialog.css"),
		dojo.moduleUrl("dojox", "widget/Dialog/Dialog.css")
	],
	
	constructor: function (args)
	{
//	    ////////console.log("constructor	plugins.files.Dialog.constructor(args)");
		this.args = args;
		this.message = args.message;
		this.parentFunction = args.parentFunction;
		this.url = args.url;
		this.query = args.query;
		this.launchdialogWindow();
	},
	
	launchdialogWindow : function ()
	{
//	    ////////console.log("launchdialogWindow	plugins.files.Dialog.launchdialogWindow()");
		var dialogWindow = this;

		// CONSTRUCT INPUT ELEMENTS FOR LOGIN WINDOW
		var table = document.createElement("table");
		table.className = "dialogTable";

			var tr1 = document.createElement("tr");
		
				// SHOW MESSAGE
				var td1 = document.createElement("td");
				var text1 = document.createTextNode(this.message);
				td1.setAttribute("colspan", 2);
				td1.appendChild(text1);

			tr1.appendChild(td1);		
				
			var tr2 = document.createElement("tr");
		
				// DISPLAY 'YES' AND 'NO' BUTTONS
				var yesButton = new dijit.form.Button(); //forget to delete
				yesButton.setLabel("Yes");
				yesButton.domNode.setAttribute("class", "dialogButton");

					
				yesButton.onClick = function(e)
				{
//				    ////////console.log("yesButton.onClick	plugins.files.Dialog.yesButton.onClick(e)");
					
					dialogWindow.query += "&modifier=overwrite";
					dialogWindow.parentFunction(dialogWindow.url, dialogWindow.query);
					dialogWindow.fadeOut("yes");
				} 
		
				var yesTd = document.createElement("td");
				yesTd.setAttribute("align", "center");
				yesTd.setAttribute("colspan", 2);
				yesTd.appendChild(yesButton.domNode);
		
				// DISPLAY 'YES' AND 'NO' BUTTONS
				var noButton = new dijit.form.Button(); //forget to delete
				noButton.setLabel("No");
				noButton.domNode.setAttribute("class", "dialogButton");
		
				var dialogWindow = this;

				var noTd = document.createElement("td");
				noTd.setAttribute("align", "center");
				noTd.setAttribute("colspan", 2);
				noTd.appendChild(noButton.domNode);
		
			tr2.setAttribute("class", "centeredRow");
			tr2.appendChild(yesTd);
			tr2.appendChild(noTd);
		
		table.appendChild(tr1);
		table.appendChild(tr2);
		
		document.body.appendChild(table);

		// CREATE LOGIN WINDOW
		var progDialog = new dojox.widget.Dialog ({
			id: 				"loginDialog",
			dimensions: 		[250,200],
			draggable: 			true,
			sizeDuration: 		200,
			sizeMethod:      	"combine",
			viewportPadding:	"125",
			showTitle: 			"true",
			title: 				"Confirmation"
			
		}, "progDialog" );		
		progDialog.attr("class", "centered");
		
		this.dialogWidget = progDialog;
		
		// SHOW DIALOGUE
		// LATER: FIX THIS ERROR 'Error undefined running custom onLoad code'
		progDialog.setContent(table);
		progDialog.startup();
		progDialog.show();
	},

	fadeOut: function()
	{
//	    ////////console.log("fadeOut	plugins.files.Dialog.fadeOut()");
		// FADE OUT LOGIN WINDOW
		dojo.fadeOut({ node: "loginDialog", duration: 700 }).play();
		setTimeout( "dijit.byId('loginDialog').destroy()", 700);
	}

}); // END
