var args = "input.inputfile.value,output.readfile.value";
var inputParams = "inputfile,readfile";
var paramFunction = "if ( inputfile != null && inputfile != '' ) return inputfile; if ( readfile != null && readfile != '' ) return readfile;";

try {
    var funcString = "var func = function(" + inputParams + ") {" + paramFunction + "}";
    console.log("funcString: " + funcString);
    eval(funcString);
}
catch (error) {
    console.log("error: " + error);
}
