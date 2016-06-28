var Gpath = "Z:\Anna\IF experiments\";
var Gchannel = "red";

macro "Mask clusters of pores" {
	Dialog.create("Mask clusters of pores");
	Dialog.addChoice("Choose channel", newArray("green", "red"), "red");
	Dialog.addNumber("Set lower threshold", 51);
	Dialog.addNumber("Set upper threshold", 255)
	Dialog.show();
	channel = Dialog.getChoice();
	lower = Dialog.getNumber();
	upper = Dialog.getNumber();
	Gchannel=channel;
	path = getDirectory("Choose a directory");
	Gpath=path;
	image1 = getTitle();
	run("Duplicate...", "title=pores.tif");	
	selectWindow(image1);
	run("Duplicate...", "title=mask.tif");	
	selectWindow(image1);
	close();
	selectWindow("mask.tif");
	setThreshold(lower, upper);
	run("Convert to Mask");
	run("Invert");
	run("Divide...", "value=255.000");
	imageCalculator("Multiply create", "pores.tif","mask.tif");
	selectWindow("Result of pores");
	saveAs("Tiff", Gpath + "mask_" + Gchannel + ".tif");
	selectWindow("pores.tif");
	close();
}

macro "Detect pores" {
	rename("ITCN_results.tif");
	run("Split Channels");
	selectWindow("ITCN_results.tif (blue)");
	close();
	selectWindow("ITCN_results.tif (green)");
	close();
	selectWindow("mask.tif");
	run("Multiply...", "value=255.000");
	run("Distance Map");
	run("Subtract...", "value=4");
	setThreshold(1, 255);
	run("Convert to Mask");
	run("Divide...", "value=255.000");
	imageCalculator("Multiply create", "mask.tif","ITCN_results.tif (red)");
	//run("Image Calculator...", "image1=mask.tif operation=Multiply image2=[ITCN_results.tif (red)] create");
	run("Invert LUT");
	saveAs("Tiff", Gpath + "results_corrected_" + Gchannel + ".tif");
}

macro "Make circle ROI around pores" {
	run("Colors...", "foreground=white background=black selection=green");
	setThreshold(255, 255);
	run("Convert to Mask");
	run("Set Measurements...", "  centroid redirect=None decimal=4");
	run("Analyze Particles...", "size=1-1 pixel circularity=0.00-1.00 clear display add");
	dotnumber=roiManager("Count");
	diameter=7;
	for(i=0;i<dotnumber;i++) {
		roiManager("Select", i);
		getSelectionCoordinates(x, y);
		circlex=x[0]-(diameter+1)/2;
		circley=y[0]-(diameter+1)/2;
		makeOval(circlex, circley, diameter, diameter);
		roiManager("Add");
	}
	for(i=0;i<dotnumber;i++) {
		roiManager("Select", 0);
		roiManager("Delete");
	}
}

macro "Remove ROI that are not pores" {

}


macro "-"{}

//ROI combining (100322)
//Kota Miura (miura@embl.de) CMCI EMBL Heidelberg
//http://cmci.embl.de

var Groiroidistance = 3;

macro "Set ROI-ROI distance threshold"{
	Groiroidistance = getNumber("Max ROI-ROI distance to combine (in pixels)", Groiroidistance);
}

macro "Combine ROIs with small ROI-ROI distance"{
	gpath = getDirectory("Choose Green Ch ROI directory");
	rpath = getDirectory("Choose Red Ch ROI directory");
	Gsavepath = getDirectory("Choose G Ch save directory");

	GroilistA = getFileList(gpath);
	RroilistA = getFileList(rpath);
	GxA = newArray(GroilistA.length);
	GyA = newArray(GroilistA.length);
	RxA = newArray(RroilistA.length);
	RyA = newArray(RroilistA.length);
	for (i=0; i<GroilistA.length; i++) {
		GxA[i] = ReturnXcoord(GroilistA[i]);
		GyA[i] = ReturnYcoord(GroilistA[i]);		
	}
	for (i=0; i<RroilistA.length; i++) {
		RxA[i] = ReturnXcoord(RroilistA[i]);
		RyA[i] = ReturnYcoord(RroilistA[i]);
	}
	posA = newArray(GroilistA.length); // position in array for the ROI with the distance closest red - ROI;
	distA = newArray(GroilistA.length); // distance to the closest red - ROI;
	for (i=0; i<GroilistA.length; i++) {
		mindist = 10000;
		minpos =0;	
		for (j=0; j<RroilistA.length; j++) {
			sumsq = pow((GxA[i] -RxA[j]),2) + pow((GyA[i] -RyA[j]),2);
			dist = pow(sumsq,0.5);
			if (mindist>dist) {
				mindist =dist;
				minpos = j;
			}
		}
		posA[i] = minpos;
		distA[i] = mindist;
	}
	distance_threshold = Groiroidistance; //global variable. Changed by another macro above
	reddoneA = newArray(RroilistA.length);
	roiindex=0;
	roiManager("reset");

	setBatchMode(true);
/*	for (i=0; i< GroilistA.length; i++){
		if (distA[i] <distance_threshold){
			print("ChG ROI index:"+ i + "("+GxA[i]+","+GyA[i]+") -> nearest RchROI index:" + posA[i]+" distance" + distA[i]);
			roiManager("Open", gpath+GroilistA[i]);
			roiManager("Open", rpath+RroilistA[posA[i]]);
			roiManager("Deselect");
			call("ROIcombine_.combineROIs", roiindex, roiindex+1);
			roiManager("Add");
			roiManager("Select", roiindex+1);
			roiManager("Delete");
			roiManager("Select", roiindex);
			roiManager("Delete");
			roiManager("Select", roiindex);
			//roiManager("Set Color", "yellow");

			reddoneA[posA[i]] = 1;	
		} else {
			roiManager("Deselect");
			roiManager("Open", gpath+GroilistA[i]);
			roiManager("Select", roiindex);
			//roiManager("Set Color", "green");
		}
		roiindex++;

	}
*/

/*			roiManager("Open", gpath+GroilistA[1]);
			roiManager("Open", rpath+RroilistA[posA[1]]);
			roiManager("Deselect");
			//call("ROIcombine_.combineROIs", 0, 1);
			roiManager("Combine");

			roiManager("Add");
			roiManager("Select", 1);
			roiManager("Delete");
			roiManager("Select", 0);
			roiManager("Delete");
*/

	for (i=0; i< GroilistA.length; i++){
		if (distA[i] <distance_threshold){
			print("ChG ROI index:"+ i + "("+GxA[i]+","+GyA[i]+") -> nearest RchROI index:" + posA[i]+" distance" + distA[i]);
			roiManager("Open", gpath+GroilistA[i]);
			roiManager("Open", rpath+RroilistA[posA[i]]);
			roiManager("Deselect");
			//roiManager("Combine");
			//call("ROIcombine_.combineROIs", 0, 1);
			roiManager("Combine");
			roiManager("Add");
			roiManager("Select", 1);
			roiManager("Delete");
			roiManager("Select", 0);
			roiManager("Delete");
			roiManager("Select", 0);
			//roiManager("Set Color", "yellow");
			op = Gsavepath+"c"+GroilistA[i]+"_"+RroilistA[posA[i]]+".zip";
			roiManager("Save", op);
			reddoneA[posA[i]] = 1;	
			roiManager("Select", 0);
			roiManager("Delete");

		} else {
			roiManager("Deselect");
			roiManager("Open", gpath+GroilistA[i]);
			roiManager("Select", 0);
			//roiManager("Set Color", "green");
			op = Gsavepath+"g"+GroilistA[i]+".zip";
			roiManager("Save", op);
			roiManager("Select", 0);
			roiManager("Delete");

		}
		roiindex++;

	}
	
	for (i=0; i< RroilistA.length; i++){
		if (reddoneA[i] == 0) {	
			roiManager("Deselect");
			roiManager("Open", rpath+RroilistA[i]);
			roiManager("Select", 0);
			//roiManager("Set Color", "red");
			op = Gsavepath+"r"+RroilistA[i]+".zip";
			roiManager("Save", op);
			roiManager("Select", 0);
			roiManager("Delete");
		}		
	}	
	setBatchMode("exit and display" );
}

function ReturnYcoord(roiFilename){
	ycoordstring = substring(roiFilename, 0, 4);
	ycoord = parseInt(ycoordstring);
	return ycoord;

}

function ReturnXcoord(roiFilename){
	xcoordstring = substring(roiFilename, 5, 9);
	xcoord = parseInt(xcoordstring);
	return xcoord;
}


macro "Show combined and none combined ROIs"{
	Gsavepath = getDirectory("Choose processed ROI directory");
	GroilistA = getFileList(Gsavepath);
	for(i=0; i<GroilistA.length; i++) {
		roiManager("Open", Gsavepath + GroilistA[i]);
//		if (lengthOf(GroilistA[i])<20) {
		if (startsWith(GroilistA[i], "g")) {
			currentcount = roiManager("count");
			roiManager("Select", currentcount -1);
			roiManager("Set Color", "green");
		}
		if (startsWith(GroilistA[i], "r")) {
			currentcount = roiManager("count");
			roiManager("Select", currentcount -1);
			roiManager("Set Color", "red");
		}

	}
}

	
