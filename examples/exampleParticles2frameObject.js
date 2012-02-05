//this example assumes that there are data
//in results table with at least 4 columns:
// X, Y, Area and Slice
// (e.g. particle analysis results of a stack)
// data in each row will be stored in frameA.cells[] array
// each with var particleobj. 
// Kota Miura (miura@ embl.de)

rt = ResultsTable.getResultsTable();
xA = rt.getColumn(rt.getColumnIndex("X"));
yA = rt.getColumn(rt.getColumnIndex("Y"));
areaA = rt.getColumn(rt.getColumnIndex("Area"));
sliceA = rt.getColumn(rt.getColumnIndex("Slice"));

//converting java array to javascript array
xJSA = [];
yJSA = [];
areaJSA = []; 
sliceJSA = [];
for (var i =0; i < xA.length; i++){
	xJSA.push(xA[i]);
	yJSA.push(yA[i]);
	areaJSA.push(areaA[i]);	
	sliceJSA.push(sliceA[i]);
	
}
data =[xJSA, yJSA, areaJSA, sliceJSA];

//Check object types
IJ.log("sliceA class: " + Object.prototype.toString.call(sliceA));
IJ.log("sliceJSA class: " + Object.prototype.toString.call(sliceJSA));

//class for each cell
var parricleobj = function(id, coorda){
	this.id = id;
	this.x = coorda[0];
	this.y = coorda[1];
	this.area = coorda[2];
	this.frame = coorda[3];
	this.prelinedID = 0;
	this.postlinkedID = []; //supposed to be an array
	this.distance2next = []; //suppeed to be an array	
}

//class for each frame, containing cell objects array
var frameobj = function(slicenum){
	this.frame = slicenum;
	this.cells = [];
}

//transposing data matrix, for ease in usage.
function transp(incoords){
	var transposed = [] 
//	for(var i = 0; i < incoords[0].length; i++){
	for(var i in incoords[0]){
		transposed.push(incoords.map(function(v){return v[i];}));
	}
	return transposed;
}

var tdata = transp(data);


function toFrameA(indata, intdata){
	var firstframe = Math.min.apply(Math, indata[3]);
	var lastframe = Math.max.apply(Math, indata[3]);
	var frames = lastframe - firstframe + 1;
	var fA = [];
	for (i = 0; i < frames; i++){
		fA.push(new frameobj(i + firstframe));
	}	
	for (var i = 0; i <intdata.length; i++){
		var acell = new parricleobj(i, intdata[i]);
		fA[acell.frame-1].cells.push(acell);
	}
	return fA;
}
var frameA = toFrameA(data, tdata);
IJ.log(frameA.length);
IJ.log(frameA[0].frame);
IJ.log(frameA[1].cells.length);
IJ.log(frameA[1].cells[3].id);
IJ.log(frameA[1].cells[3].x);

