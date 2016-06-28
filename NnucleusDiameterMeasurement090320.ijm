/*
checking 2d radius for comparing diferences due to segmentation algorithms, staining protocols.

090421	Implemented scaling by reading scale from 3D image. 

*/


macro "dev. detect DAPI rim"{
	rimposxA = newArray(36);
	rimposyA = newArray(36);
	centx =100;
	centy = 100;

	//SetToHighestIntensitySlice();	//optional
	RimDetectorBinary(rimposxA, rimposyA, centx, centy);

	run("Select None");
	run("Duplicate...", "title=detected_rim");
	run("RGB Color");
	for(i=1; i<rimposxA.length; i++){
		setColor(255, 0, 0);
		drawLine(rimposxA[i-1], rimposyA[i-1], rimposxA[i], rimposyA[i]);
	}
}

var GXYscale = 1;

//090421
function XYscaleSetter() {
	getVoxelSize(stackw, stackh, Gzscale_um, stackunit);
	if(Gzscale_um==0) {
		print("no info on voxel depth associated with the image");
		exit("failed getting scale info: check the log window");
	} else {
		//GXYscale = stackw;
		GXYscale = stackw * 10000; //when the scale is in cm, convert to um

		print("XYscale: "+GXYscale+" [um]");
	}
}

macro "-"{}

var Gnuccount=0;
var G_GID;
var GThNucL =1;
var GThNucH =255;
var 	Gtitle="twst";

macro "DAPI 2D radius measurement (ROI in the Active Window) [F1]" {
	dapiID = getImageID();
	SegmentandMeasureBucDiameter(dapiID, 0);	 
	//SegmentandMeasureBucDiameter(dapiID, 1);	//method 2008 

}

macro "DAPI 2D radius measurement (recorded ROI)" {
	K_nucradiusmeasureMain(0);
}

macro "DAPI 2D radius measurement (recorded ROI) segmentation 2008" {
	K_nucradiusmeasureMain(1);
}


function K_nucradiusmeasureMain(segmentationMethod) {
	// results table ROI list to array
	if (nResults==0) exit("nothing in results window");
	nucnum= nResults;
	roilabelA = newArray(nucnum);
	roixA = newArray(nucnum);
	roiyA = newArray(nucnum);
	roiwA = newArray(nucnum);
	roihA = newArray(nucnum);
	for (i=0; i<nucnum; i++){
		roilabelA[i] = getResultLabel(i);
		roixA[i] = getResult("roiX", i);
		roiyA[i] = getResult("roiY", i);
		roiwA[i] = getResult("roiWidth", i);
		roihA[i] = getResult("roiHeight", i);
	}
	run("Clear Results");
	Gnuccount=0;

	//loop for nucleus, segmentation, measurement to array
	for (i=0; i<nucnum; i++){
		//activating window
		fileinfostr = roilabelA[i];
		dapititle = returnDapiTitle(fileinfostr);
		selectWindow(dapititle);
		dapiID = getImageID();
		print("Nuclear Radius Estimation Working on "+ dapititle);
		if (segmentationMethod ==0) {
			makeRectangle(roixA[i],roiyA[i],roiwA[i],roihA[i]);
			SegmentandMeasureBucDiameter(dapiID, 0);
		}
		if (segmentationMethod ==1) {	//2008 method
			run("Select None");
			dapiID = getImageID();
			if (i==0) getAutoThresholdNucleusNoWindowsetter(); //090308 only for the segmentation strategy in 2008
 			else
				if (roilabelA[i] != roilabelA[i-1])
					getAutoThresholdNucleusNoWindowsetter(); //090308 only for the segmentation strategy in 2008
			makeRectangle(roixA[i],roiyA[i],roiwA[i],roihA[i]);
			SegmentandMeasureBucDiameter(dapiID, 1);
		}
	}
}



macro "clear counter"{
	Gnuccount=0;
}

macro "result label DAPI title converter"{
	// results table ROI list to array
	if (nResults==0) exit("nothing in results window");
	nucnum= nResults;
	roilabelA = newArray(nucnum);
	roixA = newArray(nucnum);
	roiyA = newArray(nucnum);
	roiwA = newArray(nucnum);
	roihA = newArray(nucnum);
	for (i=0; i<nucnum; i++){
		roilabelA[i] = getResultLabel(i);
		roixA[i] = getResult("roiX", i);
		roiyA[i] = getResult("roiY", i);
		roiwA[i] = getResult("roiWidth", i);
		roihA[i] = getResult("roiHeight", i);
	}

	newdapiwinname = getString("new name?", returnDapiTitle(roilabelA[i]));
	run("Clear Results");
	Gnuccount=0;

	//list the results in results window and log window.
	for (i=0; i<nucnum; i++){
		Gnuccount+=1;
		dirpath = returnPath(roilabelA[i]);
		fileinfostr = dirpath + ";"+newdapiwinname; 
		setResult("Label", i, fileinfostr);
		setResult("nucID", i,  Gnuccount);
		setResult("roiX", i, roixA[i]);
		setResult("roiY", i, roiyA[i]);
		setResult("roiWidth", i, roiwA[i]);
		setResult("roiHeight", i, roihA[i]);

	}
	updateResults();	
}

function returnPath(fileinfostr){
	tempstrA = split(fileinfostr, ";");
	retstr=tempstrA[0];
	return retstr;
}

//090114
//fileinfostr = dirpath + ";"+dapititle + ";"+lamintitle;
function returnDapiTitle(fileinfostr){
	tempstrA = split(fileinfostr, ";");
	retstr=tempstrA[1];
	return retstr;
}



//090303 Gauss blur for finding threshold value, and Gauss blur for actual segmentaiton
// after segmentation, hole is filled and then eroded
function KotasSegmentationEval2para(gausssigma1, gausssigma2) {
	currentID = getImageID();
	run("Duplicate...", "title=[tempforThresholding]"); // for evaluation 	
	op = "sigma="+gausssigma1;
	run("Gaussian Blur...", op);
	run("MultiThresholder", "Otsu");
	getThreshold(lower, upper);
	close();
	print("Otsu Lower Upper = "+lower+"-"+upper);
	selectImage(currentID);
	op = "sigma="+gausssigma2;
	run("Gaussian Blur...", op);
	setThreshold(upper, 255);
	run("Convert to Mask", "  black");
	run("Fill Holes");
	//for(i=0; i<gausssigma2; i++) run("Erode");
	for(i=0; i<2; i++) run("Erode");
	for(i=0; i<2; i++) run("Dilate");
	return upper;
}


// working on 090320
function ReturnAverageDAPIDiameter(nucbinaryID){
	selectImage(nucbinaryID);
	rimposxA = newArray(36);
	rimposyA = newArray(36);
	centroidA = newArray(2);
	CalcCentroidBinary(centroidA);
	checkcebtroid=getPixel(centroidA[0], centroidA[1]);
	if(checkcebtroid !=0) {
		RimDetectorBinary(rimposxA, rimposyA, centroidA[0], centroidA[1]);
		sumDiameter=0;
		for(i=0; i<rimposxA.length; i++) {
			sumDiameter += sqrt(pow((rimposxA[i] - centroidA[0]), 2) + pow((rimposyA[i] - centroidA[1]), 2));
			//print(sumDiameter);
		}
		averageDiameter = sumDiameter / rimposxA.length;
	} else averageDiameter = 0/0;
	print("ave radius = " + averageDiameter + "[pixels]");
	return averageDiameter;
}


//centroid 090320 
function CalcCentroidBinary(centroidA){
	getDimensions(ww, hh, channels, slices, frames);
	poscounter=0;
	xpossum =0;
	ypossum=0;
	for (i=0; i<hh; i++){
		for (j=0; j<ww; j++){
			if (getPixel(j, i)>0) {
				xpossum +=j;
				ypossum +=i;
				poscounter+=1;
			}		
		}	
	}
	centroidA[0] = xpossum /poscounter; //x
	centroidA[1] = ypossum /poscounter; //y
	print("DAPI centroid:"+centroidA[0]+","+centroidA[1]);
}


//090108 deviated from 
function SetToHighestIntensitySlice(){
	run("Select None");	//081212
	//G_GID = getImageID();	//dapi ID
	//setBatchMode(true);
	run("Duplicate...", "title=[temp_thrsholdFinder] duplicate");		//081212
	tempID = getImageID();		//081212
	run("Gaussian Blur...", "sigma=3 stack");
	intdenseA=newArray(nSlices);
	for (i=0; i<nSlices; i++) {
		setSlice(i+1);
		run("Select All");
		getRawStatistics(nPixels, mean);
		intdenseA[i] = mean;
		//print("slice="+i+1+" mean int="+mean);
	}
	selectImage(tempID); close();
	maxint = 0;
	maxpos = 0;
	for(i=0; i<intdenseA.length; i+=1) {
		if (intdenseA[i]>maxint) {
			maxint= intdenseA[i];
			maxpos = i;
		}
	}
	print("Max Intensity Slice ="+ maxpos+1);
	//setBatchMode("exit and display");
	setSlice(maxpos+1);
	return (maxpos+1);
} 

//segmentationMethod = 0 New March 2009
//segmentationMethod = 1 Old 2008

function SegmentandMeasureBucDiameter(dapiID, segmentationMethod){
	selectImage(dapiID);
	XYscaleSetter();	//090421
	getSelectionBounds(rx, ry, rw, rh);
	if ((rx==0) && (rw==getWidth())) 	
		exit("Need a Rectangular Selection in Nucleus Channel");
	print("ROI position:x,y="+rx+", " +ry+" w,h"+rw+", "+rh );

	Gnuccount+=1; 

	print("-------------------NUC segmentation-----------------------");
	dirpath = getDirectory("image");
	dapititle = getTitle();
	fullpath = getDirectory("image") + getTitle();
	print("Window: "+getTitle());
		//if (Gmeascount2 ==0) run("Clear Results");
	nucnameNo = "nuc" + Gnuccount;
	//nucleusname = getString("label for this nucleus", nucnameNo );
	nucleusname = nucnameNo;
	print("Processing for "+nucleusname);

	//setBatchMode(true);
	run("Duplicate...", "title=[NucleusCrop Original] duplicate"); // for intensity 
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	nucOrgID = getImageID();

	maxintslice = SetToHighestIntensitySlice();
	print("max int slice = "+maxintslice );

	run("Duplicate...", "title=[Nucleus_2D]");	//2d
	nuc2DID = getImageID();

	run("Duplicate...", "title=[Nucleus_Segmentation]");	//2d
	nucID = getImageID();
	setBatchMode("exit and display");
	if (segmentationMethod ==0) KotasSegmentationEval2para(37, 1); //37, 1

	if (segmentationMethod ==1) {
		run("Gaussian Blur...", "sigma=3 stack");	//normally in the preprocessing
		KotasSegmentation2D(GThNucL, GThNucH); //090308	old strategy. 
	}
	selectImage(nucID );
	run("Fill Holes");
	selectImage(nucOrgID); close();
	selectImage(nuc2DID ); close();

	if (CheckNucTouchingEdge() ==0) {
		//measurement
		print("-------------------Nuclear Radius Measusment -----------------------");
		nucdiameter = ReturnAverageDAPIDiameter(nucID);
		nucdiameter *=GXYscale;		//090421
		//list the results in results window and log window.
		currentcount = nResults;
		fileinfostr = dirpath + ";"+dapititle; // + ";"+lamintitle;
		setResult("Label", currentcount , fileinfostr);
		setResult("nucID", currentcount ,  Gnuccount);
		setResult("roiX", currentcount , rx);
		setResult("roiY", currentcount , ry);
		setResult("roiWidth", currentcount , rw);
		setResult("roiHeight", currentcount , rh);
		setResult("NucDiameter", currentcount , nucdiameter);
		updateResults();
	} else {
		print("Ignored "+nucnameNo + ":: segmented nucleus touching edge");
	}
	selectImage(nucID ); 
	fullpathnucname = fullpath+ nucnameNo+".tif";
	saveAs("Tiff", fullpathnucname);
	selectImage(nucID ); close();
	print("-------------------Finished Measusment -----------------------");
}

// ------------------

function RimDetector(rimposxA, rimposyA, centx, centy, degincrements) {
	for (i=0; i<36; i++) {
		deg = degincrements*i;
		getDimensions(width, height, channels, slices, frames);
		if (width > height) roiradius = height/2 -1;
		else roiradius = width/2 -1;
		setLineROIwithAngle(centx , centy , roiradius, deg);
		intA = getProfile();
		intcumA = newArray(intA.length);
		CumulateArray(intA, intcumA);
		maxpos = ReturnSteepestPointCum(intcumA, 7);
		//markpeakXA = newArray(maxpos, maxpos);
		//markpeakA = newArray(0, intcumA[maxpos]);
		rad = deg/180*3.1415;
		rotx = cos(rad)*maxpos + centx;
		roty = sin(rad)*maxpos +centy;	
		rimposxA[i] = rotx;
		rimposyA[i] = roty;
	}

	
//	Plot.create("Profile", "X", "int", intcumA);
//	Plot.add("circles", intA);
//	Plot.add("line", markpeakXA, markpeakA);	
}

function CumulateArray(inA, outA) {
	for(i = 0; i<inA.length; i++) {
		if (i==0) {
			outA[i] = inA[i];
		} else {
			outA[i] = inA[i]+outA[i-1];
		}
	}
}

function RimDetectorBinary(rimposxA, rimposyA, centx, centy) {
	for (i=0; i<36; i++) {
		deg = 10*i;	
		setLineROIwithAngle(centx , centy , 90, deg);
		intA = getProfile();
		intA = getProfile();
		edgepos = ReturnBinaryEdigeRotate(intA);
		if (edgepos ==-1) {		//090324
			rimposxA[i] = centx;
			rimposyA[i] = centy;
		} else {
			rad = deg/180*3.1415;
			rotx = cos(rad)*edgepos + centx;
			roty = sin(rad)*edgepos +centy;	
			rimposxA[i] = rotx;
			rimposyA[i] = roty;
		}
	}

	
//	Plot.create("Profile", "X", "int", intcumA);
//	Plot.add("circles", intA);
//	Plot.add("line", markpeakXA, markpeakA);	
}

//set ROI and getPeakPosition
function setLineROIwithAngle(centx, centy, radius, deg){
	rad = deg/180*3.1415;
	rotx = cos(rad)*radius + centx;
	roty = sin(rad)*radius+centy;
		// here might need routine to avoid outside the image frame
	makeLine(centx, centy, rotx, roty);	// could be opposite, depending on the result of slope detection protocol
}

function ReturnBinaryEdigeRotate(profileA) {
	edgepoint =0; 
	if (profileA[0] !=255) {
		print("not measuring binary, or maybe nuclear shape is not circular disc");
		edgepoint = -1; 		//090324
	} else {					//090324
		i =0;
		while(profileA[i]==255) i++;
		edgepoint = i;
	}
	//print("edge x="+edgepoint);
	return edgepoint; 
}



function calcDeviationradially(rimposxA, rimposyA, nucID,centx, centy, dapiedgeposxA, dapiedgeposyA, minimdist2A) {
	selectImage(nucID);
	for(i=0; i<rimposxA.length; i++) {
		//print("deg"+i*10);
		minimdist2A[i] = RadialDeviation(rimposxA[i], rimposyA[i], centx, centy, dapiedgeposxA, dapiedgeposyA, i);
		//print("dist2="+minimdist2A[i]);
	}
}

//090115 deviation along radial axis, emanating from the centroid of nucleus
function RadialDeviation(rimposx, rimposy, centx, centy, dapiedgeposxA, dapiedgeposyA, iter){
	getDimensions(width, height, channels, slices, frames);
	if ((centx) > (width - centx)) radx =  (width-centx);
	else radx = centx;

	if ((centy) > (height - centy)) rady = (height - centy);
	else rady = centy;

	if (radx > rady) roiradius = rady -1;
	else roiradius = radx -1;

	rimdist = Return2Ddist(rimposx, rimposy, centx, centy);

	currentpixel = getPixel(rimposx, rimposy);
	//print("rim Dapi int: "+currentpixel );
	
	edgex =1000000;
	edgey =1000000;
	radincrement =0;
	direction = 0;
	counter = 0;
	do {
		radincrement +=1;
		inwardx = round( (rimposx - centx) / rimdist * (rimdist - radincrement) + centx);
		inwardy = round( (rimposy - centy) / rimdist * (rimdist - radincrement) + centy);

		outwardx = round( (rimposx - centx) / rimdist * (rimdist + radincrement) + centx);
		outwardy = round( (rimposy - centy) / rimdist * (rimdist + radincrement) + centy);
		//print("in("+inwardx +","+inwardy+")");
		//print("out("+outwardx +","+outwardy+")");
		if (getPixel(inwardx,inwardy) !=currentpixel ) {
			edgex = inwardx; 
			edgey = inwardy; 
			direction = -1;
		}
		else {
			if (getPixel(outwardx,outwardy) !=currentpixel ) {
				edgex = outwardx; 
				edgey = outwardy; 
				direction = 1;
			}
		}
			
	} while ((edgex==1000000) || (counter>2000)) ;
	//print("DAPI edge:=("+edgex+", "+edgey+")");
	dapiedgeposxA[iter] =edgex;
	dapiedgeposyA[iter] =edgey;
	
	deviation = (Return2Ddist(rimposx , rimposy , edgex, edgey) * direction) ;
	return deviation;
}

// for systematic analysis, No Nucleus Window setter
function getAutoThresholdNucleusNoWindowsetter() {
	roiresume = 1;
	getSelectionBounds(rx, ry, rw, rh);
	if ((rx==0) && (rw==getWidth())) roiresume = 0;
	run("Select None");

	setBatchMode(true);
	run("Duplicate...", "title=[temp_thrsholdFinder] duplicate");	
	tempID = getImageID();		//081212
	run("Gaussian Blur...", "sigma=3 stack");
	intA=newArray(nSlices);
	for (i=0; i<nSlices; i++) {
		setSlice(i+1);
		run("Select All");
		getRawStatistics(nPixels, mean);
		intA[i] = mean;
		//print("slice="+i+1+" mean int="+mean);
	}
	maxint = 0;
	maxpos = 0;
	for(i=0; i<intA.length; i+=1) {
		if (intA[i]>maxint) {
			maxint= intA[i];
			maxpos = i;
		}
	}
	print("Max Intensity Slice ="+ maxpos+1);
	setSlice(maxpos+1);
	run("MultiThresholder", "Maximum Entropy");	//old: for saturated signals
	//run("MultiThresholder", "Otsu");		//081218 for linear signals
	getThreshold(lower, upper);
	lower = upper+1;		//  for max entropy conversion
	upper = 255;		// 
	//resetThreshold();
	print("max slice="+maxpos +1);
	print("Auto Low="+lower+" Upper="+upper);

	GThNucL =  lower;
	GThNucH =  upper;
	Gtitle = getTitle();
	run("Grays");
	print(getTitle()+" --> assigned as the threshold image");
	print("Nucleus Threshold set to - Low:"+GThNucL + "High:"+GThNucH);
	selectImage(tempID); close();		//081212
	setBatchMode("exit and display");
	//setThreshold(lower, upper);
	if (roiresume ==1) makeRectangle(rx, ry, rw, rh); 
}

// this is theinitial version, used between 0809 and 0812. 
// threshold level is automatically set using FULL frame (including many nucleus).
// --> this has problem, when nucleus DAPI intensity is not saturated. 
function KotasSegmentation2D(thresLow, threshigh) {
	run("Gaussian Blur...", "sigma=3");
	setThreshold(GThNucL, GThNucH);
	run("Convert to Mask", "  black");
}

//090324
// 1 if touching, otherwise 0
function CheckNucTouchingEdge(){
	getDimensions(ww, hh, channels, slices, frames);
	touchflag=0;
	for (i=0; i<ww; i++) {
		if (getPixel(i, 0)>0) {
			touchflag=1;
			i =ww;
		}
		if (getPixel(i, hh-1)>0) {
			touchflag=1;
			i =ww;
		}
	}
	for (j=0; j<hh; j++) {
		if (getPixel(0, j)>0) {
			touchflag=1;
			j =hh;
		}
		if (getPixel(ww-1, j)>0) {
			touchflag=1;
			j =hh;
		}
	}
	return touchflag;
} 

/*
macro "test touch check" {
 print(CheckNucTouchingEdge());
}
*/

//***************************** begin assign windows *********************** copied from K_3DdistancemapV2.ijm

var G_GID;
var G_RID;
var Gtitle;
var Rtitle;

//window ID assign manually. 
macro "Assign Windows  [f3]" {
	twoImageChoice();
	selectWindow(Gtitle);	//high
	G_GID = getImageID();
	selectWindow(Rtitle);	//low (signal)
	G_RID = getImageID();
}


//Kota: choosing two images among currently opened windows
function twoImageChoice() {
	imgnum=Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("select two images");
	//Dialog.addNumber("number1:", 0);
 	//Dialog.addNumber("number2:", 0);
	Dialog.addChoice("Ch Signal", wintitleA);
	Dialog.addChoice("Ch Nucleus", wintitleA);
 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 = Dialog.getNumber();;
 	Rtitle = Dialog.getChoice();
	Gtitle = Dialog.getChoice();
	print("Nucleus:   "+Gtitle);
	print("Signal:    " + Rtitle);
}

function CountOpenedWindows(imgIDA) {
	imgcount=0;
	for(i=0; i>-2000; i--) {
		if(isOpen(i)) {
			imgIDA[imgcount]=i;
			imgcount++;
		}
	}
}

function Wincount() {
	wincounter=0;
	for(i=0; i>-2000; i--) {
		if(isOpen(i)) {
			wincounter++;
			//print(i);
		}
	}
	return wincounter;
}

function WinTitleGetter(idA,titleA) {
	for (i=0;i<idA.length;i++) {
		selectImage(idA[i]);
		titleA[i]=getTitle();
	}
}

macro "shift finder" {
	selectImage(G_RID);
	getDimensions(ww, hh, channels, slices, frames);
	makeRectangle(ww/4, hh/4, ww/2, hh/2);
	run("Copy");
	newImage("lowch", "8-bit Black", ww/2, hh/2, 1);
	run("Paste");
	lowID=getImageID();
	newImage("highch", "8-bit Black", ww/2, hh/2, 1);
	highID=getImageID();
	maxdif = 1000000000000;
	setBatchMode(true) ;
	for(i=(-1*(ww/4)+1); i<(ww/4)-1; i+=2){
		for(j=(-1*(hh/4)+1); j<(hh/4)-1; j+=2){
			selectImage(G_GID);
			makeRectangle(ww/4+i, hh/4+j, ww/2, hh/2);
			run("Copy");
			selectImage(highID);
			run("Paste");
			imageCalculator("Difference create",highID,lowID);
			getRawStatistics(nPixels, mean);
			close();
			if ((nPixels * mean)<maxdif) {
				maxdif = (nPixels * mean);
				xshift = i;
				yshift = j;
			}
		}
	}
	setBatchMode("exit and display") ;
	print("xshift="+xshift);
	print("yshift="+yshift);

	selectImage(G_GID);
	makeRectangle(ww/4+xshift, hh/4+yshift, ww/2, hh/2);
	run("Copy");
	selectImage(highID);
	run("Paste");
	
}




