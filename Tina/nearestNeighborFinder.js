importClass(Packages.ij.gui.Overlay);
importClass(Packages.java.awt.Color);


// get arrays of data from results table
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
//create a 2D array
dataA =[xJSA, yJSA, areaJSA, sliceJSA];

IJ.log("sliceA class: " + Object.prototype.toString.call(sliceA));
IJ.log("sliceJSA class: " + Object.prototype.toString.call(sliceJSA));

//dataA = [xA, yA, areaA];

//class for storing single pair information
var apair = function (x1, y1, x2, y2){
	this.x1 = x1;
	this.y1 = y1;
	this.x2 = x2;
	this.y2 = y2;
	this.dist =
		Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
}

//class for each cell
var parricleobj = function(id, coorda){
	this.id = id; //ID within full data, not for each frame
	this.inframeid = 0; //ID within frame
	this.x = coorda[0];
	this.y = coorda[1];
	this.area = coorda[2];
	this.frame = coorda[3];
	this.dist2next = 0;
	this.prelinkedID = 0;
	this.linkedID = []; //ID within each frame
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

var tdataA = transp(dataA);


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
	for (var i in fA){
		fA[i].cells.map(function (v, id){v.inframeid = id;});
	}
	return fA;
}
var frameA = toFrameA(dataA, tdataA);
IJ.log(frameA.length);
IJ.log(frameA[0].frame);
IJ.log(frameA[1].cells.length);
IJ.log(frameA[1].cells[3].id);
IJ.log(frameA[1].cells[3].x);

// distance arrays

//test extracting two initial frames 
//sdataA1 = retOneFrameData(dataA, 1);
//sdataA2 = retOneFrameData(dataA, 2);

//extracts data for single frame from full data
function retOneFrameData(LdataA, slicenum){
	var sdataA = [];
	for(var i in LdataA)
		sdataA.push(sliceOneframe(LdataA[i], sliceA, slicenum));
	return sdataA;
}

function sliceOneframe(posA, sA, slicenum){
	return posA.slice(sA.indexOf(slicenum), sA.lastIndexOf(slicenum)+1);
}

// generate a table of distances, from particler at timepoint t to timepoint t+1
function getAllDistancePairs1(dA, timepoint){
	if ((timepoint+1) < dA[0].length ){
		var data1 = retOneFrameData(dA, timepoint); 
		var data2 = retOneFrameData(dA, timepoint+1);
		IJ.log("timepoint1 length: " + data1[0].length);
		IJ.log("timepoint2 length: " + data2[0].length);
		var distObj2D =[];
		for(var i in data1[0]){
			var v1 = data1.map(function (v){return v[i];}); //values at row i
			var distobjA = [];
			for(var j in data2[0]){
				var v2 = data2.map(function (v){return v[j];});
				var curpair = apair(v1[0], v1[1], v2[0], v2[1]);
				distobjA.push(curpair); 			 
			}
			distObj2D.push(distobjA);	
		}
		return distObj2D;
	} else {
		return null;
	}
}

// generate a table of distances, from particler at timepoint t to timepoint t+1
function getAllDistancePairs(fA, timepoint){
	if ((timepoint) < fA.length ){	//not to exceed the frame length
		var data1 = fA[timepoint-1]; 
		var data2 = fA[timepoint];
		IJ.log("timepoint1 length: " + data1.cells.length);
		IJ.log("timepoint2 length: " + data2.cells.length);
		var distObj2D =[];
		for(i in data1.cells){
			var cell1 = data1.cells[i]; // i th cell object 
			var distobjA = [];
			var distA = [];
			for(var j in data2.cells){
				var cell2 = data2.cells[j];
				var curpair = new apair(cell1.x, cell1.y, cell2.x, cell2.y);
				distobjA.push(curpair);
				distA.push(curpair.dist); 			 
			}
			distObj2D.push(distobjA);
			var mindist = Math.min.apply(Math, distA);
			fA[timepoint-1].cells[i].dist2next = mindist;			
			fA[timepoint-1].cells[i].linkedID.push(distA.indexOf(mindist));	
		}
		return distObj2D;
	} else {
		return null;
	}
}

//pair1 = new apair(0, 0, 10, 20);
//IJ.log(pair1.dist);

//dist2DA = getAllDistancePairs(dataA, 1);
//dist2DA = getAllDistancePairs(frameA, 1);
/*
IJ.log("disancetable dim 1 length: " + dist2DA.length);
IJ.log("disancetable dim 2 length: " + dist2DA[0].length);
IJ.log(dist2DA[0][0].dist);
*/
var stack = IJ.getImage();
for (var j = 0; j < frameA.length-1; j++){
	var dist2DA = getAllDistancePairs(frameA, j+1);
	stack.setSlice(j+1);
	for (var i in frameA[j].cells){
		var linked = frameA[j].cells[i].linkedID[0];
		//IJ.log(linked);
		if (linked != -1){
			var celllinked = frameA[j+1].cells[linked];
			overlayLine(frameA[j].cells[i].x, frameA[j].cells[i].y, celllinked.x, celllinked.y);
		}
	}
}

/*
minvalA = [];
for(var i in dist2DA){
	var tempA = dist2DA[i].map(function(v){return v.dist});
	minval = Math.min.apply(Math, tempA);
	IJ.log(minval);
	minvalA.push(minval);
}
for(var i in minvalA) IJ.log("cell "+i+": " + minvalA[i]);
*/	

function overlayLine(x1, y1, x2, y2){
	var imp = IJ.getImage();
	var roi1 = Arrow( x1, y1, x2, y2);
	//roi1 = Line(x1, y1, x2, y2);
	roi1.setWidth(1.5);
	roi1.setHeadSize(3);
	imp.setRoi(roi1);
	var overlay = imp.getOverlay();
	if (overlay != null)
		overlay.add(roi1);
	else
		overlay = Overlay(roi1);
	var red = Color(1, 0, 0);
	overlay.setStrokeColor(red); 
	imp.setOverlay(overlay);
	imp.updateAndDraw() ;

	//IJ.log("head " + roi1.getDefaultHeadSize());
	//IJ.log("head " + roi1.getDefaultWidth());
}


/// tests of reading out multidimensional data
/*
sdataA2.map(readoutCol);

function readoutCol(v, idx, ar){
	var o = {id:idx};
	v.map(readoutRaws, o);
}
function readoutRaws(v, idx, ar){
	IJ.log(""+this.id + ":"+ v);
}
*/
/// test down to here

