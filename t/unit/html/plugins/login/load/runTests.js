require([
	"dojo/_base/declare",
	"dojo/dom",
	"dojo/dom-attr",
	"doh/runner",
	"t/unit/doh/util",
	"t/unit/doh/Agua",
	//"plugins/core/Util/ViewSize",
	"plugins/login/Login",
	"dojo/domReady!"
],

function (
	declare,
	dom,
	domAttr,
	doh,
	util,
	Agua,
	//ViewSize
	Login
) {

// SET window.Agua GLOBAL VARIABLE
window.Agua = Agua;
Agua.cookie('username', "admin");

// TESTED OBJECT
var object;
window.object = object;

// TEST NAME
var test = "unit.plugins.login.load";
console.log("# test: " + test);
dom.byId("pagetitle").innerHTML = test;
dom.byId("pageheader").innerHTML = test;

doh.register(test, [
{
	name: "new",
	setUp: function(){
		Agua.data = {};
		Agua.cookie('username', 'testuser');
		Agua.cookie('sessionid', '9999999999.9999.999');
		//Agua.data.groups = util.fetchJson("groups.json");
		//console.log("new    Agua.data: ");
		//console.dir({Agua_data:Agua.data});

		//domClass.add(dom.byId("attachPoint"), "sharing");
		//domClass.add(document.body, "dojoDndCopy");
	},
	runTest : function(){
		console.log("# print");

		var attachPoint	=	dom.byId("attachPoint");
		console.log("new    attachPoint:");
		console.dir({attachPoint:attachPoint});

		object = new Login({
			attachPoint: dom.byId("attachPoint")
		});
		
		object.showProgressBar();
		object.message.innerHTML = "Load test";

		var percent = 25;
		object.progressBar.set({value:percent, progress:percent});	
		object.progressMessage.innerHTML = "progress message";

		var style = domAttr.get(object.progressBar.internalProgress, "style");
		console.log("assertEqual style: " + style);
		doh.assertEqual(style, "width: " + percent + "%;");

		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred();

		// SHOW PROGRESS PANE
		setTimeout(function() {
			try {
				percent = 50;
				object.progressBar.set({value:percent, progress:percent});	
				object.progressMessage.innerHTML = "progress message";	
				var style = domAttr.get(object.progressBar.internalProgress, "style");
				console.log("assertEqual style: " + style);
				doh.assertEqual(style, "width: " + percent + "%;");
			} catch(e) {
			  deferred.errback(e);
			}
		}, 1000);

		// SHOW PROGRESS PANE
		setTimeout(function() {
			try {
				percent = 75;
				object.progressBar.set({value:percent, progress:percent});	
				object.progressMessage.innerHTML = "progress message";

				var style = domAttr.get(object.progressBar.internalProgress, "style");
				console.log("assertEqual style: " + style);
				doh.assertEqual(style, "width: " + percent + "%;");

				deferred.callback(true);
	
			} catch(e) {
			  deferred.errback(e);
			}
		}, 2000);

	}

}

]);	// doh.register

	//Execute D.O.H. in this remote file.
	doh.run();

}); // dojo.addOnLoad

		
////// Agua TEST MODULES
////dojo.require("t.doh.util");
////
////// TESTED MODULES
////dojo.require("plugins.core.Agua");
////dojo.require("plugins.home.Home");
////
////dojo.addOnLoad(function(){
////
////Agua = new plugins.core.Agua({
////	cgiUrl : dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
////});
//
////Agua.cookie('username', 'testuser');
////Agua.cookie('sessionid', '9999999999.9999.999');
////Agua.loadPlugins([
////	"plugins.login.Controller"
////]);
//
////Agua.login = new plugins.login.Login();
////console.log("agua.html    Completed");
//
//Agua.startPlugins = function () {
//	console.log("OVERRIDE Agua.startPlugins()");
//
//	var args = [
//		[10, 2, "Loading module 1"],
//		[10, 4, "Loading module 2"],
//		[10, 6, "Loading module 3"],
//		[10, 8, "Loading module 4"],
//		[10, 10, "Loading module 5"]
//	];
//
//	var delay = 1000;	
//	var commands = new Array;
//	for ( var i = 0; i < args.length; i++ ) {
//		commands.push({
//			func: [ this.pluginManager.percentProgress, this, args[i][0], args[i][1], args[i][2]],
//			pauseAfter: delay
//		});
//	}
//	console.log("OVERRIDE Agua.startPlugins    commands: ");
//	console.dir({commands:commands});
//	
//	this.sequence = new dojox.timing.Sequence({});
//	this.sequence.go(commands, function() {
//		console.log('OVERRIDE Agua.startPlugins    Doing this.sequence.go(commands)');
//	});	
//}
//
//login = Agua.login;
//console.dir({login:login});
//console.dir({statusBar:Agua.login.statusBar});
////console.dir({robot:doh.robot});
//
////require(["doh/runner", "doh/robot"], function(doh, robot){
////    doh.register("doh/robot",
////    {
////        name: "dojorobot1",
////        timeout: 6900,
////        setUp: function(){
////            document.getElementById('textbox').value="hi";
////        },
////        runTest: function(){
////            var d = new doh.Deferred();
////            robot.mouseMove(30, 30, 500);
////            robot.mouseClick({left:true}, 500);
////            robot.typeKeys(" again", 500, 2500);
////            robot.sequence(d.getTestCallback(function(){
////                doh.is("hi again", document.getElementById('textbox').value);
////            }), 900);
////            return d;
////        }
////    });
////    doh.run();
////});
//
////require(["doh/runner", "doh/robot"], function(doh, robot){
////    doh.register("doh/robot",
////    {
//
//doh.register("plugins.login.Login",
//[{
//	name: "login",
//	runTest: function() {
//		console.log("Test    login:");
//		console.dir({login:login});
//		// SET DEFERRED OBJECT
//		var deferred = new doh.Deferred();
//
//		// SHOW PROGRESS PANE
//		setTimeout(function() {
//			try {
//				var target = login.username.textbox;
//				console.log("Test    Doing mouseMove target: " + target);
//				console.dir({target:target});
//				//console.log("Test    Doing mouseMove doh.robot: " + doh.robot);
//				//console.dir({doh_robot:doh.robot});
//				//doh.robot.mouseMove(target, 500);
//				//console.log("Test    AFTER mouseMove");
//				//doh.robot.mouseClick({left:true}, 500);
//				//console.log("Test    AFTER mouseClick");
//				//doh.robot.typeKeys("admin", 500, 2500);
//				//console.log("Test    AFTER typeKeys");
//				//console.log("Test    Getting username");
//				//var username = login.statusBar.username.get("value");
//				//console.log("username: " + username);
//				//console.dir({login_username:login.username});
//				//robot.sequence(d.getTestCallback(function(){
//					//doh.is("hi again", document.getElementById('textbox').value);
//				//}), 900);
//	
//				//console.log("Doing login.handleLogin()");
//				//login.handleLogin({"sessionid":"1357123476.1594.258"}, "testuser");
//	
//				console.log("Doing login.hideInputs()");
//				login.hideInputs();	
//	
//				console.log("Doing login.showProgressBar()");
//				login.showProgressBar();
//
//				console.log("Doing Agua.startPlugins()");
//				Agua.startPlugins();
//				
//	
//				deferred.callback(true);
//	
//			} catch(e) {
//			  deferred.errback(e);
//			}
//		}, 5000);
//	}		
//}]
//
//)	// doh.register
//
////})	// function
//
//////]}}
//
////Execute D.O.H. in this remote file.
//doh.run();
//
//}); // dojo.addOnLoad
//
//	
