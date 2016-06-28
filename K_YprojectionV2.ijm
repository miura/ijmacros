//		-------- K_Yprojection.ijm------------
//
//Kota Miura (CMCI EMBL Heidelberg) 2007, Distribution requires author's permission.
//http://www.embl.org/cmci

// coded for Marianne 
//(1) Y projection profile two channels (y-integrated x profiler with mask)
// two stacks are required, 1ch will be the mask and the second channel intnesity profile
// will be measured according to the structure segmented in the 1st channel. 
// Image Threshold is used to segment the first image. Lower value can be adjusted by the 
// user in the dialog window. 
// Intensity profile is measured along x-axis, and intensity along Y-axis is integrated. 
// All frames are measured each, and stored in the Results table. 
//(2) Profile Plotter
// Loads data from the results table according to the global variables from the measurment above. 
// "Plot Increments" adjusts the sampling frequency within stack. 
// trace color is printed out in the Log window. 

// 070222
// first version K_YprojectionV1.ijm completed. measurement and plotting in one macro. 
// 070223
// seperate to two macros. (renamed to K_YprojectionV2.ijm)
// - changes (1) measurement is done for all frames, seperate visualization
//	(2) plotting macro, allways start from second frame, adjust increments. 
//080429
// added modules for Julie, to measure static images
//	macro "Rotate Sync 2ch to Horizontal"	(line ROI should be drawn from left to right)
//	macro "Get threshold Lower"
// added option "noise spot removal button" for removing spots outside MT in the mask. 	

var G_Gtitle="ig1";	// LIB-> main Green channel
var G_Rtitle="ig2";	// LIB-> main Red channel


var G_r_lower = 95; 

var PlotRange_y_max=-50000; //LIB
var PlotRange_y_min=50000; //LIB
var G_checkStartFrame=1;

var G_startframe = 1;
var G_endframe = 2;

var G_plotIncrements = 2; //LIB --> frame increments for plotting 2 means 2, 4, 6; 3 means 3, 6, 9...
var G_w=472;	//row length , or the x_width of the profile
var G_x_profileA_length=20296;

var G_noiseremoveswitch =1;	//080429
var Gstartarea = 2000; 	//particle size to ignore	//080429

//******************************************************
//080429

//requires line selection, from lef to right
macro "Rotate Sync 2ch to Horizontal" {
	twoImageChoice070222();
	selectWindow(G_Rtitle);
	Rid = getImageID();
	selectWindow(G_Gtitle);
	Gid = getImageID();
	selectImage(Rid);
	if (selectionType() != 5) exit("You need to do a line selection!") ;
	getLine(x1, y1, x2, y2, lineWidth);
	rotate = atan2(y2-y1, x2-x1)*180/PI;
	rotate*=-1;
	print("rotation: "+rotate);
	op = "angle="+rotate+ " grid=0";
	run("Arbitrarily...", op);
	selectImage(Gid);
	run("Arbitrarily...", op);
}

macro "Get threshold Lower" {
	getThreshold(lower, upper);
	if (lower==-1) exit("Need a thresholded active image");
	print("Threshold Low: "+lower);
	G_r_lower=lower;
}
//***************************************************************
macro "-"{}

macro "Y projection profile two-channels" {
	twoImageChoice070222();
	selectWindow(G_Gtitle);
	Gid = getImageID();
	selectWindow(G_Rtitle);
	Rid = getImageID();
	run("Duplicate...", "title=mask duplicate");
	maskID=getImageID();
	setThreshold(G_r_lower,255);
	run("Convert to Mask", "stack");
	if (G_noiseremoveswitch) maskID = CheckParticleNumber(); //080429
	run("Divide...", "stack value=255");	
	imageCalculator("Multiply create 32-bit stack", maskID,Gid);
	conbineID=getImageID();
	rename("measurement_stack.tif"); 

	w=getWidth();
	h=getHeight();
	
	sampleframes=nSlices;

	x_profileA=newArray(w * sampleframes);
	x_heightA=newArray(w * sampleframes);

	for (k=0; k<sampleframes; k++) {	//stack frame flipper
		setSlice(k+1);
		for (i=0; i<w;i++) {
			makeLine(i, 0, i, (h-1));
			y_profA=getProfile();
			heightCount=0;
			integInt=0;
			for (j=0; j<y_profA.length; j++) {
				if (y_profA[j]!=0) heightCount++;
				integInt+=y_profA[j];
			}
			x_profileA[k*w+i] = integInt;
			x_heightA[k*w+i] = heightCount;
		}
	}
	selectImage(maskID);
	setThreshold(1,255);
	print("****************************************");
	print("Red Ch:"+ G_Rtitle + "  Green Ch:"+G_Gtitle);
	print("Threshold for Red Channel Structre:"+ G_r_lower +"-255");
	//print("Frame Increment:"+G_plotIncrements); 
	output_MultipleResults(x_profileA, x_heightA, w, "f");

	// following global varibales used for the plotting
	G_w = w;
	G_x_profileA_length=x_profileA.length;
}

macro "Profile Plotter" {
	plotAdjuster();
	fullstack_ProfileA=newArray(G_x_profileA_length);
	fullstack_ylengthA=newArray(G_x_profileA_length);
	RetrieveResults(fullstack_ProfileA, fullstack_ylengthA, "f");

	stacklength = (G_x_profileA_length/G_w) - G_checkStartFrame;
	if (((stacklength/G_plotIncrements) - floor(stacklength/G_plotIncrements) ) !=0) {
		plotnum = floor(stacklength/G_plotIncrements) +1;
	} else {
		plotnum = floor(stacklength/G_plotIncrements);
	}
	profilePlotA = newArray(plotnum * G_w);
	yheightPlotA = newArray(plotnum * G_w);
	for (i=0; i<plotnum; i++ ) {
		//print("frame"+ (i * G_plotIncrements+G_checkStartFrame+1));
		for (j=0; j<G_w; j++ ) {
			profilePlotA[i * G_w + j] = fullstack_ProfileA[(i * G_plotIncrements+G_checkStartFrame) *G_w + j];		
			yheightPlotA[i * G_w + j] =fullstack_ylengthA[(i * G_plotIncrements+G_checkStartFrame) *G_w + j];	
		}
	}

	K_createMultileProfilePlot(profilePlotA, G_w );
	K_createYcountPlot(yheightPlotA, G_w );
}

macro "-"{}

/*
macro "CheckExtraentitty" {
	CheckParticleNumber();
}
*/

//modified 080429
function CheckParticleNumber(){
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=pixels global");
	inputID = getImageID();
	correctionflag = 0;
	run("Set Measurements...", "area centroid perimeter fit circularity redirect=None decimal=3");
//	run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear include stack");
	run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear stack");

	if (nResults>nSlices) correctionflag = 1;
	if (correctionflag) {
		approxprimodimumsize = 150000;
		startarea = Gstartarea;
		loopflag = 1;
//		setBatchMode(true);
		while ((loopflag==1) ||  (startarea> approxprimodimumsize)) {
//			op = "size="+startarea+"-Infinity circularity=0.00-1.00 show=Nothing display clear include stack";
			op = "size="+startarea+"-Infinity circularity=0.00-1.00 show=Nothing display clear stack";
			run("Analyze Particles...", op);
			if (nResults==nSlices) loopflag =0;
			if (nResults>nSlices) startarea+=2;
			if (nResults<nSlices) startarea-=2;
			print("Current cutoff Area:" + startarea);
		}	
//		op = "size="+startarea+"-Infinity circularity=0.00-1.00 show=Masks display clear include stack";
		op = "size="+startarea+"-Infinity circularity=0.00-1.00 show=Masks display clear stack";
		run("Analyze Particles...", op);
		run("Invert LUT");
		outputID = getImageID();
		selectImage(inputID);
		close();
		print("extra area check terminated at "+ (startarea-1));
	} else {
		outputID = inputID;
		print("No removing of extraparticles");
	}
	rename("Mask");
	return outputID;
}

//**************** LIB *************************


// dialog window for selecting two channel image stacks and setting threshold. 
function twoImageChoice070222() {
	imgnum=Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("select two images");
	Dialog.addChoice("Ch Tublin (mask)", wintitleA);
	Dialog.addNumber("Threshold Low:", G_r_lower);
	Dialog.addChoice("Ch Eg5 (measure)", wintitleA);
	//Dialog.addNumber("Sampling: start frame", G_startframe);
	//Dialog.addNumber("Sampling: end frame", G_endframe);
	Dialog.addCheckbox("Noise spot Removal", G_noiseremoveswitch);

 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 
 	G_Rtitle = Dialog.getChoice();
	G_r_lower = Dialog.getNumber();	
	G_Gtitle = Dialog.getChoice();
	//G_startframe  = Dialog.getNumber();
	//G_endframe  = Dialog.getNumber();
	G_noiseremoveswitch = Dialog.getCheckbox();
	//print(Gtitle + Rtitle);
}

// dialog window for setting plotting conditions. 
function plotAdjuster() {

 	Dialog.create("Plotter");
	Dialog.addNumber("Plot Increments", G_plotIncrements);
	Dialog.addCheckbox("Start from 2nd frame", G_checkStartFrame);
 	Dialog.show();
	G_plotIncrements = Dialog.getNumber();
	G_checkStartFrame = 	Dialog.getCheckbox();
	
}

// stores imageID in the Array
function CountOpenedWindows(imgIDA) {
	imgcount=0;
	for(i=0; i>-2000; i--) {
		if(isOpen(i)) {
			imgIDA[imgcount]=i;
			imgcount++;
		}
	}
}

// counts how many windows are opened.
function Wincount() {
	wincounter=0;
	for(i=0; i>-2000; i--) {
		if(isOpen(i)) {
			wincounter++;
		}
	}
	return wincounter;
}

// using the imageID array constructed above, window titles are stored in a string array
function WinTitleGetter(idA,titleA) {
	for (i=0;i<idA.length;i++) {
		selectImage(idA[i]);
		titleA[i]=getTitle();
	}
}

//graph

// modified 070222, 070223
// creates multile plot from single array containing multiple plots. 
function K_createMultileProfilePlot(pA, xwidth) {
	K_updatePlotRange(pA);
	Plot.create("Intensity profile", "X axis [pixels]", "integrated intensity");	
	Plot.setLimits(0, xwidth, PlotRange_y_min*0.95, PlotRange_y_max*1.05);
	colorArray=newArray("black", "blue", "cyan", "darkGray", "gray", "green", "lightGray", "magenta", "orange", "pink", "red", "white","yellow");
	plotnum=pA.length/xwidth;
	for (m=0; m<plotnum; m++) {
		Plot.setColor(colorArray[m-(floor(m/13)*13)]);
		plotArray=newArray(xwidth);
		for (n=0; n<xwidth; n++) plotArray[n]=pA[xwidth*m+n];
		Plot.add("line", plotArray);
	}
	//texts
	Plot.setColor(colorArray[0]);
	ops="Threshold Red Channel:"+ G_r_lower +"-255  Frame Increment:"+G_plotIncrements; 
	Plot.addText(ops, 0, 0);
	Plot.show();
	PrintCurveInfo(colorArray, plotnum);	//Log window
}

// 070222 above function modified
// creates multile plot from single array containing multiple plots. 
function K_createYcountPlot(pA, xwidth) {
	Plot.create("Ydistance", "X axis [pixel]", "Thresholded Pixel [pixel]");
	Plot.setLimits(0, xwidth, K_retrunArrayMin(pA)*0.95, K_retrunArrayMax(pA) *1.05);
	colorArray=newArray("black", "blue", "cyan", "darkGray", "gray", "green", "lightGray", "magenta", "orange", "pink", "red", "white","yellow");
	plotnum=pA.length/xwidth;
	for (m=0; m<plotnum; m++) {
		Plot.setColor(colorArray[m-(floor(m/13)*13)]);
		plotArray=newArray(xwidth);
		for (n=0; n<xwidth; n++) plotArray[n]=pA[xwidth*m+n];
		Plot.add("line", plotArray);
	}
	//texts
	Plot.setColor(colorArray[0]);
	ops="Threshold Red Channel:"+ G_r_lower +"-255  Frame Increment:"+G_plotIncrements; 
	Plot.addText(ops, 0, 0);
	Plot.show();
}

//to set a plot range to fit a curve. global variables are used.
function K_updatePlotRange(referenceA) {
       for (k=0;k<referenceA.length;k++) {
               if (PlotRange_y_max<referenceA[k])
                       PlotRange_y_max=referenceA[k];
               if (PlotRange_y_min>referenceA[k])
                       PlotRange_y_min=referenceA[k];
       }
}

function K_retrunArrayMax(anA) {
	aA_max=-500000; //LIB
	for (k=0;k<anA.length;k++) if (aA_max<anA[k]) aA_max=anA[k];
	return aA_max;
 }

function K_retrunArrayMin(anA) {
	aA_min=500000; //LIB
	for (k=0;k<anA.length;k++) if (aA_min>anA[k]) aA_min=anA[k];
	return aA_min;
 }

// 	printouts array into multiple column.
// 	length of the column is defined by segLength.
// 	prefix of the column tiitle defined by string col_titlepre
function output_MultipleResults(rA, heightA, segLength, col_titlepre) {
	run("Clear Results");
	columnnum=rA.length/segLength;
	for(i = 0; i < columnnum; i++) {
		currentColTitle1="int_"+ col_titlepre+(i+1);
		currentColTitle2="Ycount_"+ col_titlepre+(i+1);
		for(j = 0; j < segLength; j++) {
	            	if (i==0) setResult("x", j, j);
	           		setResult(currentColTitle1, j, rA[i * segLength + j]);
	           		setResult(currentColTitle2, j, heightA[i * segLength + j]);
		}
	}
	updateResults();
}

// 070223 retrieves data from result window and store them in Array
function RetrieveResults(profileA,ylengthA,col_titlepre) {
	x_width = nResults;
	if (x_width != G_w) exit("Results table Missing or Modified");
	ColumnSetNumber=profileA.length/x_width;
	for (i=0; i<ColumnSetNumber; i++) {
		currentColTitle1="int_"+ col_titlepre+(i+1);
		currentColTitle2="Ycount_"+ col_titlepre+(i+1);
		for (j=0; j< x_width; j++) {
	            	//if (i==0) getResult("x", j, j);
	           		profileA[i * x_width + j]=getResult(currentColTitle1, j);
	           		ylengthA[i * x_width + j]=getResult(currentColTitle2, j);			
		}
	}
}

function PrintCurveInfo(colorA, samplenum) {
	for (i=0; i<samplenum;i++) {
		//print("frame"+(i+1)*G_plotIncrements+": "+colorA[i]);
		 print("frame"+(i * G_plotIncrements+G_checkStartFrame+1)+": "+colorA[i-(floor(i/13)*13)]);
	}
}



