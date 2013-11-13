// ALLOW THE USER TO SELECT FROM 'AGUA' USER AND 'ADMIN' USER APPLICATIONS AND DRAG THEM INTO WORKFLOWS

define([
	"dojo/_base/declare",
	"dojo/_base/lang",
	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"plugins/core/Common/Util",
	"dojo/domReady!"
],

function (declare,
	lang,
	_Widget,
	_TemplatedMixin,
	CommonUtil
) {

return declare("plugins.dijit.Version",
	[ _Widget, _TemplatedMixin, CommonUtil ], {

////}}}}}

// attachPoint : DomNode or widget
// 		Attach this.mainTab using appendChild (domNode) or addChild (tab widget)
//		(OVERRIDE IN args FOR TESTING)
attachPoint : null,

// templateString: String
//		HTML template
templateString: dojo.cache("plugins", "dijit/templates/version.html"),

// baseClass : String
//		Base CSS class for widget
baseClass : "plugins_dijit_Version",

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("plugins/dijit/css/version.css")
],

// majorVersion : Integer
//		Major version number
majorVersion : "0",

// minorVersion : Integer
//		Minor version number
minorVersion : "0",

// patchVersion : Integer
//		Patch version number
patchVersion : "1",

// suffix : String
//		Version type ("-alpha.1", "-beta.1", "-rc.1", "-rc.2", etc.)
//		and/or build number ("+build.1", "+build.10", etc.)
suffix       : "build.1",

// version : String
//		Complete version string, e.g., "0.0.1+build.1"
version : null,

// locked : Boolean
//		Set to true to prevent the user from changing inputs
locked:	false,

////}}}}}

constructor : function (args) {
	console.log("Version.constructor     args:");
	console.dir({args:args});

	lang.mixin(this, args);
    
    // LOAD CSS
	this.loadCSS();		
},
postCreate : function () {
	this.startup();
},
startup : function () {
	//console.log("Version.startup     this:");
	//console.dir({this:this});

	// SET SELECTS
	this.setSelects();
	
	// ATTACH PANE TO attachPoint
	this.attachPane(this.containerNode);
	
	// SET VERSION IF DEFINED
	if ( this.version )	this.setVersionFromString(this.version); 
},
setSelects : function () {
	//console.log("Version.setSelects     this.majorSelect:");
	//console.dir({this_majorSelect:this.majorSelect});

	this.setSelectRanges();

	this.setSelectValues();
},
setSelectValues : function () {
	this.setVersion(this.majorVersion, this.minorVersion, this.patchVersion, this.suffix);
},
setSelectRanges : function () {
	this.setSelectOptions(this.majorSelect, 0, 100);		
	this.setSelectOptions(this.minorSelect, 0, 100);	
	this.setSelectOptions(this.patchSelect, 0, 100);	
},
setSelectOptions : function (select, start, stop) {
	//console.log("Version.setSelectOptions     select:");
	//console.dir({select:select});
	//console.log("Version.setSelectOptions     start: " + start);
	//console.log("Version.setSelectOptions     stop: " + stop);

	var values = [];
	//console.log("Version.setSelectOptions     values:");
	//console.dir({values:values});

	for ( var i = start; i < stop; i++ )	{	values.push(i); 	}

	for ( var i = 0; i < values.length; i++ ) {
		var option = document.createElement("OPTION");
		option.text = values[i];
		option.value = values[i];
		select.options.add(option);
	}	
},
setVersionFromString : function (versionString) {
	//console.log("Version.setVersionFromString    versionString: " + versionString);
	var version = this.parseVersion(versionString);

	//console.log("Version.setVersionFromString    version: ");
	//console.dir({version:version});
	
	if ( version ) {
		this.setVersion(version.major, version.minor, version.patch, version.release + version.build);
	}
},
parseVersion : function (versionString) {

	var regex = /^(\d+)\.(\d+)\.(\d+)(-alpha[\.\d]*|-beta[\.\d]*|-rc[\.\d]*)?(\+build[\.\d]*|\+[\.\d]*)?/;
	if ( versionString.match(regex) ) {
		//console.log("Version.parseVersion    MATCH");
		
		var version = {};
		version.major 	= parseInt(versionString.match(regex)[1]);
		version.minor 	= parseInt(versionString.match(regex)[2]);
		version.patch 	= parseInt(versionString.match(regex)[3]);
		version.release = versionString.match(regex)[4];
		version.build  	= versionString.match(regex)[5];
		
		console.log("Version.parseVersion    BEFORE REGEX version: ");
		console.dir({version:version});

		if ( version.build ) 	version.build	=	version.build.replace(/\.+$/, '');
		if ( version.release ) 	version.release	=	version.release.replace(/\.+$/, '');
		if ( version.build ) 	version.build	=	version.build.replace(/^\+/, '');
		if ( version.release ) 	version.release	=	version.release.replace(/^-/, '');

		console.log("Version.parseVersion    AFTER REGEX version: ");
		console.dir({version:version});

		if ( ! version.release )	version.release = '';
		if ( ! version.build )	version.build = '';
	
		return version;
	}
	else {
		//console.log("Version.parseVersion    NO MATCH");
	}
	
	return null;
},
setVersion : function (major, minor, patch, suffix) {
	var majorError = this.checkNumeric(major).error;
	if ( majorError ) {
		//console.log("Major version '" + major + "' error: " + majorError);
		return;
	}
	var minorError = this.checkNumeric(minor).error;
	if ( minorError ) {
		//console.log("minor version '" + minor + "' error: " + minorError);
		return;
	}
	var patchError = this.checkNumeric(patch).error;
	if ( patchError ) {
		//console.log("patch version '" + patch + "' error: " + patchError);
		return;
	}	
	
	if ( ! suffix )	suffix = "";
	
	this.majorSelect.value = major;
	this.minorSelect.value = minor;
	this.patchSelect.value = patch;
	this.suffixInput.value = suffix;
},
checkNumeric : function (value) {
	if ( ! value ) 	return {
		error : "Value not defined"
	}
	
	if ( ! value.match(/^\d+$/ ) )	return {
		error : "Value is not numeric"
	}
	
	return true;
},
versionSort : function (aVersionString, bVersionString) {
	//console.log("Version.versionSort    versions: ");
	//console.dir({versions:versions});
	//console.log("Version.versionSort    versions2: ");
	//console.dir({versions2:versions2});
	//
	//var aVersion 	= 	versions[0];
	
	
	//var bVersion	=	versions[1];
	var aVersion = this.parseVersion(aVersionString);
	var bVersion = this.parseVersion(bVersionString);
	console.log("Version.versionSort    aVersion: ");	
	console.dir({aVersion:aVersion});
	console.log("Version.versionSort    bVersion: ");
	console.dir({bVersion:bVersion});
	
	if ( aVersion.major > bVersion.major )	{ return 1 }
	else if ( bVersion.major > aVersion.major ) { return -1 }
	if ( aVersion.minor > bVersion.minor )	{ return 1 }
	else if ( bVersion.minor > aVersion.minor ) { return -1 }
	if ( aVersion.patch > bVersion.patch )	{ return 1 }
	else if ( bVersion.patch > aVersion.patch ) { return -1 }
	if ( ! aVersion.release && ! bVersion.release
		&& ! aVersion.build && ! bVersion.build )	{ return 0 }
	
	if ( aVersion.release && ! bVersion.release )	{ return -1 }
	if ( bVersion.release && ! aVersion.release )	{ return 1 }
	
	if ( aVersion.release && bVersion.release ) {
		var compare = this.compareStringNumber(aVersion.release, bVersion.release);
		console.log("Version.versionSort    compareStringNumber(aVersion->release, bVersion->release): compare");
		if ( compare != 0 )	return compare;
		if (! aVersion.build && ! bVersion.build) 	return 0;
	}
	
	if ( aVersion.build && ! bVersion.build )	{ return 1 }
	if ( bVersion.build && ! aVersion.build )	{ return -1 }
	if ( aVersion.build && bVersion.build ) {
		return this.compareStringNumber(aVersion.build, bVersion.build);
	}
	
	return 0;
},
splitStringNumber : function (string) {
	console.log("splitStringNumber    string: " + string);
	var stringObject = {};
	if ( string.match(/^([^\d^\.]+)/) ) {
		stringObject.string = string.match(/^([^\d^\.]+)/)[1];
	}
	if ( string.match(/(\d+)/) ) {
		stringObject.number = parseInt(string.match(/(\d+)/)[1]);
	}

	return stringObject;
},
compareStringNumber : function (a, b) {
	console.log("compareStringNumber    a: " + a);
	console.log("compareStringNumber    b: " + b);

	if ( !a.match(/(\d+)/) && ! b.match(/(\d+)/) ) {
		var compare = a.toLowerCase() > b.toLowerCase();
		console.log("compareStringNumber    compare: compare");
		return compare;
	}
	else {
		var aObject = this.splitStringNumber(a);
		var bObject = this.splitStringNumber(b);
		console.log("aObject: aObject");
		console.log("bObject: bObject");

		if ( aObject.string != bObject.string ) {
			var compare = a.toLowerCase() > b.toLowerCase();
			//var compare = lc(a) cmp lc(b);
			return compare;
		}
		else {
			console.log("comparing numbers");	
			if ( aObject.number === null && bObject.number === null ) {
				return 0;
			}
			else if ( aObject.number && bObject.number === null ) {
				return 1;
			}
			else if ( bObject.number && aObject.number === null ) {
				return -1;
			}
			else if ( aObject.number > bObject.number ) {
				console.log("a is larger than b");
				return 1;
			}
			else if ( bObject.number > aObject.number ) {
				console.log("b is larger than a");
				return -1;
			}
			else {
				return 0;
			}
		}
	}
},
higherSemVer : function (version1, version2) {
	console.log("Version.higherSemVer    version1" + version1);
	console.log("Version.higherSemVer    version2" + version2);

	// REMOVE ANYTHING AFTER +build.\d+
	version1.replace(/(build\.\d+)\..+/, "<$1>");
	version2.replace(/(build\.\d+)\..+/, "<$1>");
	console.log("Version.higherSemVer    version1" + version1);
	console.log("Version.higherSemVer    version2" + version2);
	
	if ( version1 === version2)	return 0 ;
	if ( version1 && version2 === null )	return 1;
	if ( version1 === null && version2 === null)	return -1;
	
	var array = [ version1, version2 ];
	var temp = dojo.clone(array);
	var sortedArray;
	if ( temp.length > 1 ) {
		sortedArray = this.sortVersions(temp);
	}
	else if ( temp.length == 1 ) {
		sortedArray = [temp[0]];
	}
	console.log("Version.higherSemVer    array: ");
	console.dir({array:array});
	console.log("Version.higherSemVer    sortedArray: ");
	console.dir({sortedArray:sortedArray});
	
	if ( this.arraysHaveSameOrder(array, sortedArray) ) {
		console.log("Version.higherSemVer    returning -1");
		return -1;
	}
	else {
		console.log("Version.higherSemVer    returning 1");
		return 1;
	}
},
arraysHaveSameOrder : function (arrayA, arrayB) {
	if ( arrayA.length != arrayB.length ) { return 0; }
	
	for (var i = 0; i < arrayA.length; i++) {
		if (arrayA[i] != arrayB[i]) { 
			return 0;
		}
	}
	return 1;
},
sortVersions : function (versions) {
	console.log("Version.sortVersions    caller: " + this.sortVersions.caller.nom);
	console.log("Version.sortVersions    BEFORE versions: ");
	console.dir({versions:versions});

	if (versions && versions.length > 1) {
		versions = versions.sort(dojo.hitch(this, this.versionSort));
	}
	console.log("Version.sortVersions    AFTER versions: ");
	console.dir({versions:versions});
	
	return versions;
}






//,
//method incrementSemVer ($currentversion, $versiontype, $releasename) {
//#$self->logDebug("versiontype", $versiontype);
//#$self->logDebug("releasename", $releasename);
//
//	#### PARSE OUT VERSIONS	
//	my ($major, $minor, $patch, $release, $build) = $self->parseSemVer($currentversion);
//	$self->logDebug("major", $major);
//	$self->logDebug("minor", $minor);
//	$self->logDebug("patch", $patch);
//	$self->logDebug("release", $release);
//	$self->logDebug("build", $build);
//	$self->logCritical("major version not defined in current version: $currentversion") and exit if not defined $major;
//	$self->logCritical("minor version not defined in current version: $currentversion") and exit if not defined $minor;
//	$self->logCritical("patch version not defined in current version: $currentversion") and exit if not defined $patch;
//
//	#### SANITY CHECK
//	if ( not defined $major ) {
//		$self->logDebug("major version not defined");
//		return;
//	}
//
//	if ( defined $releasename and $releasename ) {
//		#### VERSION TYPE CANNOT release IF RELEASE NAME IS DEFINED
//		if ( defined $versiontype and $versiontype eq "release" ) {
//			$self->logWarning("versiontype cannot be 'release' if releasename is defined: $releasename");
//			return;
//		}
//
//		#### VERSION TYPE MUST BE DEFINED IF RELEASE NAME IS DEFINED
//		#### OK 		--versiontype major --releasename alpha		1.0.0 -> 2.0.0-alpha.1
//		#### NOT OK		--releasename alpha				1.0.0  --XXXXX--> 1.0.0-alpha.1  !!!!!
//		if ( not defined $versiontype and not $release ) {
//			$self->logWarning("versiontype must be defined if releasename is defined");
//			return;
//		}
//	
//		#### MUST BE MAJOR, MINOR OR PATCH INCREMENT IF RELEASE NAME IS DEFINED AND NO RELEASE
//		#### OK 		--versiontype major --releasename alpha	1.0.0 -> 2.0.0-alpha.1
//		#### OK 		--versiontype build --releasename beta	1.0.0-alpha.1 ---> 1.0.0-beta.1+build1
//		#### NOT OK 	--versiontype build --releasename alpha	1.0.0+build1 --XXX-> 1.0.0-alpha.1+build1
//		#### NOT OK		--releasename alpha				1.0.0  --XXXXX--> 1.0.0-alpha.1  !!!!!
//		my $isversion = 1;
//		$isversion = 0 if
//			defined $versiontype 
//			and not $versiontype eq "major"
//			and not $versiontype eq "minor"
//			and not $versiontype eq "patch";
//				
//		if ( defined $versiontype
//			and not $isversion
//			and not $release
//		) {
//			$self->logWarning("versiontype must be major, minor or patch if releasename is defined");
//			return;
//		}
//
//		if ( not $isversion
//			and (
//					( $releasename eq "alpha" and $release =~ /^(alpha|beta|rc)/ )
//				or ( $releasename eq "beta" and $release =~ /^(beta|rc)/ )
//				or ( $releasename eq "rc" and $release =~ /^rc/ )
//			)
//		) {
//			$self->logWarning("releasename '$releasename' must be > current release: $release");
//			return;
//		}		
//
//		if ( not defined $versiontype
//			and (
//					( $releasename eq "alpha" and $release =~ /^(alpha|beta|rc)/ )
//				or ( $releasename eq "beta" and $release =~ /^(beta|rc)/ )
//				or ( $releasename eq "rc" and $release =~ /^rc/ )
//			)
//		) {
//			$self->logWarning("releasename '$releasename' must be > current release: $release");
//			return;
//		}		
//	}
//
//	#### INCREMENT VERSION IF VERSION TYPE IS DEFINED
//	if ( defined $versiontype ) {
//		if ( $versiontype eq "major" ) {
//			$major++ ;
//			$minor = 0;
//			$patch = 0;
//			$build = '';
//			$release = '';
//		}
//		elsif ( $versiontype eq "minor" ) {
//			$minor++;
//			$patch = 0;
//			$build = '';
//			$release = '';
//		}
//		elsif ( $versiontype eq "patch" ) {
//			$patch++;
//			$build = '';
//			$release = '';
//		}
//		elsif ( $versiontype eq "release") {
//			if ( not defined $release or not $release ) {
//				$self->logWarning("release must be defined if versiontype is release");
//				return;
//			}
//			else {
//				$release = $self->incrementMixed($release);
//			}
//		}
//		elsif ( $versiontype eq "build" ) {
//			if ( not $build ) {
//				$build = "build.1";
//			}
//			else {
//				#$self->logDebug("BEFORE build", $build);
//				$build = $self->incrementMixed($build);
//				$self->logDebug("AFTER incrementMixed, build", $build);
//			}
//		}
//	}
//
//	#### IF RELEASE NAME AND VERSION TYPE ARE DEFINED, JUST ATTACH THE
//	#### RELEASE TO THE INCREMENTED VERSION TYPE
//	####
//	#### E.G., MAJOR VERSION WITH RELEASE NAME alpha:
//	####
//	#### 	0.9.2 -> 1.0.0-alpha
//	####
//	if ( defined $releasename ) {
//		$release = $releasename;
//		$release = $release . ".1" if $release !~ /\d+$/;
//	}
//
//	#### FINAL VERSION
//	my $finalversion = "$major.$minor.$patch";
//	$finalversion .= "-$release" if $release;
//	$finalversion .= "+$build" if defined $versiontype and $versiontype eq "build";
//	$self->logDebug("finalversion", $finalversion);
//
//	return $finalversion;
//}





}); 	//	end declare

parser.parse();

});	//	end define
