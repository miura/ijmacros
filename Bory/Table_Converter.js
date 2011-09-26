/*
20110208 Bory's tool
for converting table with incremented frames and blank row with NaN
20110216 Corrected for row-mismatch with some cases. 
*/
//path = IJ.getDirectory(""); 
str = IJ.openAsString("");
strA = str.split("\n");
var framenumA = new Array(strA.length);
var distA = new Array(strA.length);
for (var i in strA){
	lineA = strA[i].split("\t");
	framenumA[i] = lineA[1];
	distA[i] =  lineA[2];
	//IJ.log(framenumA[i]);
	if (isNaN(lineA[0])) IJ.log("Nan Found at line"+i);	//added 110216
} 
IJ.log("Input Rows: " + framenumA.length); //this includes header as well
firstframe = parseInt(framenumA[1]);	//frame number in the first row
lastframe = parseInt(framenumA[framenumA.length - 1]); //frame number in the last row. 
newrows = lastframe - firstframe + 1;
IJ.log("output rows: " + newrows); 
var newframenumA = new Array(newrows);
var newdistA = new Array(newrows);
var count = 0;
//IJ.log(newdistA.length); 
for (var i = firstframe; i < (lastframe + 1); i++){
	count = 0;
	for (j = 1; j < framenumA.length; j++) 
		if (parseInt(framenumA[j]) == i) count++;
	IJ.log("frame:"+i+" -> dots: " + count);
	newframenumA[i] = i;
	if (count == 0) 		
		newdistA[i] ="";	
	else if (count == 1) {
		for (j in framenumA)
			if (framenumA[j] == i) 
				newdistA[i] = parseFloat(distA[j]);
	}
	else if (count == 2) {
		for (j = 0; j < framenumA.length; j++) {
			if (framenumA[j] == i) {
				newdistA[i] = (parseFloat(distA[j])+parseFloat(distA[j+1]))/2;
				j = framenumA.length;
			}
		}
	}
}
rt = new ResultsTable();
outstr = "";
//for (var j = 0; j < newframenumA.length; j++){
for (var j in newframenumA){	
	//IJ.log("new:" + j);
	rt.incrementCounter();
	rt.setValue("frame", j-1, j);
	if (isNaN(newdistA[j]))
		rt.setValue("ch0-ch1_dist", j-1, "");
	else
		rt.setValue("ch0-ch1_dist", j-1, newdistA[j]);
	//IJ.log(""+j + " -- "+ newdistA[j]);
	outstr = outstr + j + "\t" + newdistA[j]+"\n";
}
rt.show("Cleaned - Statistics_Distance");
//IJ.log(outstr);
IJ.saveString(outstr, "");
   
