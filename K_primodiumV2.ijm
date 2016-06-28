/* k_primodium.ijm
Kota Miura, CMCI EMBL Heidelberg
miura at embl.de (+49 6221 387 404)
2007.09 - 

for quantitation of Zebrafish Primodium dynamics (Gulcin)
071017 made a assembled macro "Process two channels for primodium centrin Analysis" 
*/

var Gch1STKID;
var Gch2STKID;
var GmaskSTKID;
var G1title="ch1";
var G2title="ch2";
 

var Ggausssize=20;
var GCentrinThreshold = 0;
var Gstartarea = 2000; 	//particle size to ignore

macro "Adjust Gauss Blurr Level"{
	Ggausssize = getNumber("Gauss Radius:" , Ggausssize);
}

macro "-"{}

//071017
macro "Process two channels for primodium centrin Analysis" {
	twoChChoice070904();

	selectWindow(G2title);
	Gch2STKID = getImageID();
	
	selectWindow(G1title);
	Gch1STKID = getImageID();
	maskID = GenerateMaskGetMidline();
	MidlineMeasureStack(maskID);

	run("Duplicate...", "Gduplicate duplicate");
	GdupicateID = getImageID();
	run("Divide...", "stack value=255");
	run("16-bit");

	selectImage(Gch2STKID);
	run("Subtract Background...", "rolling=20 stack");
	imageCalculator("Multiply create stack", Gch2STKID, GdupicateID );
	selectImage(GdupicateID );
	close();
		
}

macro "-"{}

//071017 copied from K_particletrackeroutputconverter.ijm
//070910 Changed, workwith igorPro. 
// more editing, but not required for IgorPro
// How to use:
// 1. Save the results in the Particle Tracker by "Save full report".
// 2. then execute this macro. It asks you to choose the text file saved in 1. 
// 3. Converts the file so that 
//	line1: track number
//	line2: frame number
//	line3: x position
//	line4: y position
//	line5: intensity moments of order 0
//	line6: intensity moments of order 2
//	line7: non-particle discrimination criteria
macro "Track Converter General"{
 	 print("\\Clear");
	tempstr = File.openAsString("");
	linesA=split(tempstr,"\n");
	trajectoryCount=1;
	//f1 = File.open("converted.txt");
	for (i=0; i < linesA.length; i++) {
		tempstr=linesA[i];
		comparestr="%% Trajectory " + trajectoryCount;
		if (tempstr==comparestr) {
			traj_startline=i;
			do {
				i++;
				//tempstr = linesA[i];
				//if (indexOf(linesA[i], ",")>0) linesA[i]=CommaEliminator(linesA[i]);
				paramA=split(linesA[i], " ");
				tempstr2="";
				for (j = 0; j<paramA.length; j++) {
					tempstr2=tempstr2+paramA[j]+"\t";
				}
				tempstr =""+trajectoryCount + "\t" + tempstr2;
				print(CommaEliminator(tempstr));
			} while (linesA[i]!="") 
			trajectoryCount++;
		}
		//if (tempstr=="%% Trajectories:") print(i);
	}	
	//File.close(f1);
	selectWindow("Log");
	saveAs("text");
}

//071017 copied from K_particletrackeroutputconverter.ijm
function CommaEliminator(strval) {
	while (indexOf(strval, ",")>0) {
			delindex = indexOf(strval, ",");
			returnstr = substring(strval, 0, delindex) + substring(strval, delindex+1, lengthOf(strval));
			strval = returnstr ;
	}	 	
	return strval;
}

//071017 copied from K_particletrackeroutputconverter.ijm
// frame by frame converter
//070910
macro "Frame Wise particle Positions Converter"{
 	 print("\\Clear");
	tempstr = File.openAsString("");
	linesA=split(tempstr,"\n");
	frameCount=0;
	//f1 = File.open("converted.txt");
	for (i=0; i < linesA.length; i++) {
		tempstr=linesA[i];
		comparestr="% Frame " + frameCount + ":";
		if (tempstr==comparestr) {
			//print("check");
			//traj_startline=i;
			do {
				i++;
			} while (startsWith(linesA[i], "%	Particles after non-particle discrimination") == 0);

			comparestr3="% Frame " + frameCount+1 + ":";
			i++; //onle shift
			do {
				param1A=split(linesA[i], "\t");
				paramA=split(param1A[1], " ");
				tempstr2="";
				for (j = 0; j<paramA.length; j++) {
					tempstr2=tempstr2+paramA[j]+"\t";
				}
				tempstr =""+ frameCount + "\t" + tempstr2;
				print(CommaEliminator(tempstr));
				i++;
				
			} while ((linesA[i]!=comparestr3) && (startsWith(linesA[i], "% Trajectory linking") ==0));
			print("");
			frameCount ++;
			i--;
		}
		//if (tempstr=="%% Trajectories:") print(i);
	}	
	//File.close(f1);
	selectWindow("Log");
	saveAs("text");
}

macro "-"{}

macro "Preprocess centrin 1" {
	run("Subtract Background...", "rolling=5 stack");
	run("Gaussian Blur...", "sigma=1 stack");
}

macro "Preprocess centrin 2" {
	thresmin = getNumber("Threshold low in the firstframe?", 38);
	imgRID = getImageID();
	imgw = getWidth();
	imgh = getHeight();
	imgt = nSlices;
	newImage("binarystack", "8-bit Black", imgw, imgh, imgt);
	binID = getImageID();
	setBatchMode(true);
	for (i = 0; i<imgt; i++) {
		selectImage(imgRID);
		setSlice(i+1); 
		getRawStatistics(nPixels, mean, min, max);
		if (i==0) firstmean = mean;
		if (i==0) firstmin = thresmin;
		run("Select All");
		run("Copy");

		newImage("stack", "16-bit Black", imgw, imgh, 1);
		run("Paste");
		setThreshold((firstmin * mean/firstmean), max);
		print(firstmin * mean/firstmean);
		run("Convert to Mask");
		run("Select All");
		run("Copy");
		close();

		selectImage(binID ); 
		setSlice(i+1);
		run("Paste");
	}
	setBatchMode("exit and display");

}

macro "GenerateMask"{
	Gch1STKID = getImageID();
	maskID = GenerateMaskGetMidline();
}

function GenerateMaskGetMidline(){
	blurredID = BackgroundEqualize();
	GenerateMaskThres(blurredID);
	blurredID = CheckParticleNumber();

	//GetYmidpoints(blurredID);
	//run("Restore Selection");
	return blurredID;
} 

macro "-"{}

macro "Get Centrin Distribution"{
	twoChChoice070904();

	selectWindow(G2title);
	Gch2STKID = getImageID();

	selectWindow(G1title);
	Gch1STKID = getImageID();

	blurredID = BackgroundEqualize();
	GenerateMaskThres(blurredID);
	blurredID = CheckParticleNumber();

	maskimgID = applymask(blurredID, Gch2STKID );
	selectImage(maskimgID);
	run("Divide...", "stack value=255");

	for(i = 0; i < nSlices; i++) {
		print("slice"+i+1);
		selectImage(blurredID);
		setSlice(i+1);
		GetYmidpoints(blurredID);

/*		selectImage(Gch1STKID);
		setSlice(i+1);
		run("Restore Selection");

		selectImage(Gch2STKID);
		setSlice(i+1);
		run("Restore Selection");
*/
		selectImage(maskimgID);	
		setSlice(i+1);
		run("Restore Selection");
		allsum = measureDisttimesIntensityV2();
		op = "distint";
		setResult(op, i, allsum);
		updateResults();
	}

}

macro "-"{}

function MeasureSumofDistance(){
}



function measureDisttimesIntensity(){
	getSelectionCoordinates(midxA, midyA);
	allsum = 0;
	counter = 0;
	for(i=0; i<midxA.length;i++) {
		topbound = midyA[i];
		bottombound = midyA[i];
		while ((getPixel(midxA[i], topbound) > 0) && (topbound >=0)) topbound--;
		while ((getPixel(midxA[i], bottombound) > 0) && (bottombound < getHeight()) ) bottombound++;
		print(topbound + "," + bottombound);
		currentXsum =0;
		for (j=topbound; j<bottombound+1; j++) {
			currentInt = getPixel(midxA[i], j);
			if (currentInt >GCentrinThreshold) {
				//if ((j - midxA[i]) == 0) {
				//	currentXsum += currentInt * abs(j - midyA[i]);
				//} else {
				//	currentXsum += currentInt;
				//}
				currentXsum +=  abs(j - midyA[i]);	//only distance
				counter +=1;
			}
		}
		print(currentXsum);
		allsum += currentXsum; 
	}
	return allsum/counter;		
}

// average distance
function measureDisttimesIntensityV2(){
	getSelectionCoordinates(midxA, midyA);
	allsum = 0;
	counter = 0;
	imgh = getHeight();
	for(i=0; i<midxA.length;i++) {
		for (j=0; j<imgh; j++) {
			currentInt = getPixel(midxA[i], j);
			if (currentInt >GCentrinThreshold) {
				allsum +=  abs(j - midyA[i]);	//only distance
				counter +=1;
			}
		}
		
	}
	print("total " + allsum + "  count: "+ counter+ "  average:"+allsum/counter);
	return allsum/counter;		
}

function measureDisttimesIntensityV3(){
	getSelectionCoordinates(midxA, midyA);
	allsum = 0;
	counter = 0;
	imgh = getHeight();
	for(i=0; i<midxA.length;i++) {
		for (j=0; j<imgh; j++) {
			currentInt = getPixel(midxA[i], j);
			if (currentInt >GCentrinThreshold) {
				allsum += currentInt*  abs(j - midyA[i]);	
				counter +=1;
			}
		}
		
	}
	print(allsum/counter);
	return allsum/counter;		
}

macro "Get Midline"{
	blurredID = getImageID();
	GetYmidpoints(blurredID );
}

// allxA[0] = slice number
// allxA[1] = Nan
// allxA[2] = first coordinate x 
// ....
macro "Get Midline Stack & Record"{
	blurredID = getImageID();
	MidlineMeasureStack(blurredID);
}

function MidlineMeasureStack(blurredID) {
	imgW = getWidth();
	allfA = newArray((imgW+1)*nSlices);
	allxA = newArray((imgW+1)*nSlices);
	allyA = newArray((imgW+1)*nSlices);

	for (i=0; i<nSlices; i++) {
		setSlice(i+1);
		GetYmidpoints(blurredID );
		getSelectionCoordinates(xA, yA);
		for(j=0; j<imgW; j++) {
			if (j<xA.length) {
				allxA[i * (imgW+1) + j] = xA[j];
				allyA[i * (imgW+1) + j] = yA[j];
			} else {
				allxA[i * (imgW+1) + j] = -1;
				allyA[i * (imgW+1) + j] = -1;
			}
			allfA[i * (imgW+1) + j] = i;
		}
		allfA[i * (imgW+1) + imgW] = "";
		allxA[i * (imgW+1) + imgW] = "";
		allyA[i * (imgW+1) + imgW] = "";
	}
 	 print("\\Clear");
	for (i=0; i<allxA.length; i++) {
		print(allfA[i] +"\t"+ allxA[i] + "\t " + allyA[i]);
	}
	selectWindow("Log");
	saveAs("text");
}

macro "-"{}
/*
macro "testdistancecalc" {
	measureDisttimesIntensityV2(); //dist only
	//measureDisttimesIntensityV3(); //int*dist
}
*/
function BackgroundEqualize() {
	//run("Duplicate...", "title=stkG-1.tif duplicate");
	//close();
	run("Duplicate...", "title=blurred duplicate");
	//run("Duplicate...", "blurred");
	blurredSTKID=getImageID();
	run("Gaussian Blur...", "sigma="+Ggausssize+" stack");
	//imageCalculator("Subtract create stack", GorigSTKID,blurredSTKID);
	//GmaskSTKID=getImageID();	
	return blurredSTKID;
}

//multithresholder plugin must be installed
function GenerateMaskThres(maskID){
	selectImage(maskID);
	getStatistics(area, mean, min, max, std);	
	run("MultiThresholder", "Mixture Modeling");
	getThreshold(autolower, autoupper);
	setThreshold(autoupper, max);
	run("Convert to Mask", "  black");
	run("Fill Holes", "stack");
}
/*
macro "CheckExtraentitty" {
	CheckParticleNumber();
}
*/
function CheckParticleNumber(){
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=pixels global");
	inputID = getImageID();
	correctionflag = 0;
	run("Set Measurements...", "area centroid perimeter fit circularity redirect=None decimal=3");
/*	for(i=0; i<nSlices; i++) {
		setSlice(i+1);
		run("Analyze Particles...", 
			"size=0-Infinity circularity=0.00-1.00 show=Nothing display clear include slice");
		if (nResults>1) correctionflag = 1;
	}
*/
	run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear include sstack");
	if (nResults>nSlices) correctionflag = 1;

	if (correctionflag) {
		approxprimodimumsize = 150000;
		startarea = Gstartarea;
		loopflag = 1;
//		setBatchMode(true);
		while ((loopflag==1) ||  (startarea> approxprimodimumsize)) {
			op = "size="+startarea+"-Infinity circularity=0.00-1.00 show=Nothing display clear include stack";
			run("Analyze Particles...", op);
			if (nResults==nSlices) loopflag =0;
			if (nResults>nSlices) startarea+=2;
			if (nResults<nSlices) startarea-=2;
			print("Current cutoff Area:" + startarea);
		}	
		op = "size="+startarea+"-Infinity circularity=0.00-1.00 show=Masks display clear include stack";
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
	return outputID;
}

function applymask(maskID, imgID) {
	//imageCalculator("Multiply create 32-bit", maskID,imgID);
	//imageCalculator("Multiply create 32-bit stack", maskID,imgID);
	imageCalculator("Multiply create stack", maskID,imgID);
	return getImageID();
}



function GetYmidpoints(blurredID){
	selectImage(blurredID);
	imgH = getHeight();
	imgW = getWidth();
	yposfullA = newArray(imgW);
 	//run("Clear Results");

	for(i=0; i<imgW; i++){
		makeLine(i, 0, i, imgH-1);
		intA = getProfile();
		yposfullA[i] = AveragePosition(intA);
		
	}
	nonezerocounter = 0;
	for(i=0; i<yposfullA.length; i++){
		if (yposfullA[i] > 0) nonezerocounter +=1; 
		//setResult("Yposition", i, yposfullA[i]);
	}
	//updateResults();
 	//run("Clear Results");

	print("ImageW="+ imgW + " signal"+nonezerocounter );
	yposshortA = newArray(nonezerocounter);
	xposA = newArray(nonezerocounter);
	counter = 0;
	for(i=0; i<yposfullA.length; i++){
		if (yposfullA[i] > 0) {
			yposshortA[counter] = yposfullA[i];
			xposA[counter] = i;
			counter +=1; 
		} 
	}
	makeSelection("freeline", xposA , yposshortA );

}

function AveragePosition(intA){
	ysum = 0;
	counter = 0;
	for(i=0; i<intA.length; i++) {
		if (intA[i]>0) {
			ysum += i;
			counter +=1;
		}
	}
	if (counter>0) ysum /= counter;
	return ysum;
}
/*
macro "test two choice"{
	twoChChoice070904();
}
*/
function twoChChoice070904() {
	imgnum=Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("Select Images");
	Dialog.addChoice("Ch1 (Segmentation)", wintitleA);
	Dialog.addChoice("Ch2 (centrinmeasure)", wintitleA);
/*
	Dialog.addNumber("Line Width for Measurement", G_width);
	Dialog.addCheckbox("Measure MT tip position",G_MeasureMapSwitch);
*/

 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 
 	G1title = Dialog.getChoice();
	G2title = Dialog.getChoice();

/*
	G_width = Dialog.getNumber();
	G_MeasureMapSwitch=Dialog.getCheckbox();
*/
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

//************** 071017 copied from 

macro "-" {}

//070911 works with the output textfile by "Track Converter"
macro "dynamic track plotting" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,0, 1, "red");
}

//070911 works with the output textfile by "Track Converter"
macro "dynamic spot plotting" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,1, 0, "red");
}

//070507 copied from tracking2Dv2b and modified. 
//070911 renamed and modified for direct selection of the track file. 
// track file in the format of exproted by Converter in this macro. 

function PlotTrackDynamic_stackDirect(stackID,paint, trace, color) {
	selectImage(stackID);
	frames=nSlices;
	currentxA = newArray(nSlices);
	currentyA = newArray(nSlices);
	currentfA = newArray(nSlices);
	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
	}
	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	if (color=="red") {
		rgb_r=255;
		rgb_g=0;
		rgb_b=0;
	}

	if (color=="blue") {
		rgb_r=0;
		rgb_g=0;
		rgb_b=255;
	}
	if ((paint) || (trace)){
		 run("RGB Color");
		setColor(rgb_r,rgb_g,rgb_b);
		//setForegroundColor(rgb_r,rgb_g,rgb_b);		
	}

	tracknum = 1;
	framecount = 0;

	for (k=0; k<lineA.length; k++) {
		do {
			linecontentA=split(lineA[k],"\t");
			if (linecontentA.length>1) {
				tracknum = linecontentA[0];
				currentslice = linecontentA[1];
				currentX = linecontentA[3];
				currentY = linecontentA[2];
				//print(tracknum+ "-"+currentslice + ":" + currentX + "," + currentY );
				currentfA[framecount] = currentslice;
				currentxA[framecount] = currentX;
				currentyA[framecount] = currentY;
		 		framecount++;
				k++;
			} 

		} while (linecontentA.length>1);

		for(plotloop =0; plotloop<framecount; plotloop++) { 
			setSlice(currentfA[plotloop]+1);
			if ((trace==0) && (paint==0)){
				makeOval(currentxA[plotloop]-4,currentyA[plotloop] -4, 9, 9);
				wait(20);
			}	
			if (paint) fillOval(currentxA[plotloop]-1,currentyA[plotloop] -1, 3, 3); 	//dots
			if (trace) {
				if (plotloop>0) 	{
					for (j=1; j<=plotloop; j++) {
						setColor(255,0,0);	//red if not linear
						drawLine(currentxA[j-1], currentyA[j-1], currentxA[j], currentyA[j]);
					}
				}
				//if (plotloop==framecount-1) {
				//	setForegroundColor(255,255,255);
				//	setFont("SansSerif", 10);
				//	trackID=substring(trackname, 2, lengthOf(trackname));
				//	drawString(trackID, currentX , currentY);
				//}
			} //else wait(20);			
		}			
		framecount =0;
		tracknum+=1;
	}
	setForegroundColor(255,255,255);


	selectImage(stackID);
}

macro "... track filter" {
	tracklengthmin = getNumber("Minimum tracklength?", 3);
	FilterTracks(tracklengthmin -1);
}

function FilterTracks(tracklengthTH) {
	maxtracklength = 1000;
	currentLineA = newArray(maxtracklength );
	for (i=0; i<currentLineA .length; i++) currentLineA [i] = -1;
	currentTrackNumA = newArray(maxtracklength );
	for (i=0; i<currentTrackNumA .length; i++) currentTrackNumA [i] = -1;


	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");
	lineFilteredA = newArray(lineA.length);

	tracknum = 1;
	framecount = 0;
	newlinecount =0;

	for (k=0; k<lineA.length; k++) {
		do {
			linecontentA=split(lineA[k],"\t");
			if (linecontentA.length>1) {
				//print(tracknum+ "-"+currentslice + ":" + currentX + "," + currentY );
				if (framecount ==0) currenttrack = linecontentA[0];
				currentLineA[framecount] = lineA[k];
		 		framecount++;
				k++;
			} 
		} while (linecontentA.length>1);

		if (framecount>tracklengthTH) {
			for(i =0; i<framecount; i++) print(currentLineA[i]);
			print(currenttrack);			
		}
		framecount =0;
		tracknum+=1;
	}
	selectWindow("Log");
	saveAs("text");
}

macro "Plot Midline" {
	stackID = getImageID();
	PlotMidline_stackDirect(stackID, "yellow");
}

//070911 Works with Midline file output (K_primodium.ijm). 
function PlotMidline_stackDirect(stackID, color) {
	selectImage(stackID);
	frames=nSlices;
	currentxA = newArray(getWidth());
	currentyA = newArray(getWidth());
	currentfA = newArray(getWidth());
	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
	}
	fullpathname = File.openDialog("Select a Midline File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	if (color=="red") {
		rgb_r=255; rgb_g=0; rgb_b=0;
	}
	if (color=="blue") {
		rgb_r=0; rgb_g=0; rgb_b=255;
	}
	if (color=="yellow") {
		rgb_r=255; rgb_g=255; rgb_b=0;
	}
	 run("RGB Color");
	setColor(rgb_r,rgb_g,rgb_b);

	framecount = 0;
	arraycount = 0;
	for (k=0; k<lineA.length; k++) {
		do {
			linecontentA=split(lineA[k],"\t");
			if (linecontentA.length>1) {
				currentslice = linecontentA[0];
				currentX = linecontentA[1];
				currentY = linecontentA[2];
				if (arraycount==0) framenum = currentslice;
				//currentfA[arraycount ] = currentslice;
				currentxA[arraycount ] = currentX;
				currentyA[arraycount ] = currentY;
		 		arraycount ++;
				if (currentX > 0) framecount++;
				k++;
			} 

		} while (linecontentA.length>1);
		//print("framenum="+framenum );
		//print("Array count="+arraycount);
		//print("frameount="+framecount);
		midlinexA = newArray(framecount+1);
		midlineyA = newArray(framecount+1);
		for(i=0; i<midlinexA.length; i++) {
			midlinexA[i] = currentxA[i];
			midlineyA[i] = currentyA[i];
			//print( midlinexA[i] + "," + midlineyA[i] );
		}
		selectImage(stackID);
		setSlice(framenum+1);
		//for(i=0; i<midlinexA.length; i++) drawOval(midlinexA[i], midlineyA[i], 1, 1);
		//for(i=0; i<midlinexA.length-1; i++)  drawLine(midlinexA[i], midlineyA[i], midlinexA[i+1], midlineyA[i+1]);
		drawLine(midlinexA[0], midlineyA[0], midlinexA[midlinexA.length-1], midlineyA[midlinexA.length-1]);
		//makeSelection("freeline", midlinexA, midlineyA);
		//run("Draw");
		arraycount=0;
		framecount =0;
	}
	setForegroundColor(255,255,255);
	print("processing finished");
	selectImage(stackID);
}

// 071214 create kymograph using the midline information

macro "Kymo Midline" {
	stackID = getImageID();
	KymoMidline_stackDirect(stackID);
}
var G_width = 30; 

// initialization of the kymograph image
//	width same as the image
//	height nSlices + thickness/time point

function KymoMidline_stackDirect(stackID) {
	selectImage(stackID);
	ww = getWidth();
	hh = getHeight();	
	frames=nSlices;
	currentxA = newArray(getWidth());
	currentyA = newArray(getWidth());
	currentfA = newArray(getWidth());
	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
	}
	fullpathname = File.openDialog("Select a Midline File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	thickness =3;
	//newImage("random", "16-bit Black", ww , frames*thickness, 1);
	newImage("random", "16-bit Black", ww , frames, 1);	// use resizing

	kymoID = getImageID();

	framecount = 0;
	arraycount = 0;
	for (k=0; k<lineA.length; k++) {
		do {
			linecontentA=split(lineA[k],"\t");
			if (linecontentA.length>1) {
				currentslice = linecontentA[0];
				currentX = linecontentA[1];
				currentY = linecontentA[2];
				if (arraycount==0) framenum = currentslice;
				//currentfA[arraycount ] = currentslice;
				currentxA[arraycount ] = currentX;
				currentyA[arraycount ] = currentY;
		 		arraycount ++;
				if (currentX > 0) framecount++;
				k++;
			} 

		} while (linecontentA.length>1);
		//print("framenum="+framenum );
		//print("Array count="+arraycount);
		//print("frameount="+framecount);
		midlinexA = newArray(framecount+1);
		midlineyA = newArray(framecount+1);
		for(i=0; i<midlinexA.length; i++) {
			midlinexA[i] = currentxA[i];
			midlineyA[i] = currentyA[i];
			//print( midlinexA[i] + "," + midlineyA[i] );
		}
		selectImage(stackID);
		setSlice(framenum+1);
		//for(i=0; i<midlinexA.length; i++) drawOval(midlinexA[i], midlineyA[i], 1, 1);
		//for(i=0; i<midlinexA.length-1; i++)  drawLine(midlinexA[i], midlineyA[i], midlinexA[i+1], midlineyA[i+1]);
		//drawLine(midlinexA[0], midlineyA[0], midlinexA[midlinexA.length-1], midlineyA[midlinexA.length-1]);
		makeSelection(6, midlinexA, midlineyA);	//071214 segmented line ROI
		measWideSegmentedLineIntensity(G_width, kymoID, framenum);	//071214
		selectImage(stackID);				//071214
		//makeSelection("freeline", midlinexA, midlineyA);
		//run("Draw");
		arraycount=0;
		framecount =0;
	}
	//setForegroundColor(255,255,255);
	selectImage(kymoID);
	op = "width="+ww+" height="+frames*thickness;
	run("Size...", op);
	print("processing finished");
	selectImage(stackID);
}



macro "Get Segmented Line ROI Profile Wide [f1]" {
	G_width= getNumber("ROI Width?", G_width);
	measWideSegmentedLineIntensity(G_width);
}

function measWideSegmentedLineIntensity(width, kymoID, framenum) {
	if (selectionType() !=6) exit("selection type must be a segmented line ROI");
	getSelectionCoordinates(xCA, yCA);
	op="line="+width;
	run("Line Width...", op);
	totalprofilelength=0;
	totaldistance=0;
	for (i = 0; i < xCA.length-1; i++) {
		makeLine(xCA[i], yCA[i], xCA[i+1], yCA[i+1]);
		tempProfile=getProfile();
		totalprofilelength += tempProfile.length;
		//print(i+"seg:"+tempProfile.length + "total:"+totalprofilelength);
	}
	//print(xCA.length-1+ " segments: "+ totalprofilelength);
	//print(" ******* ");
	totalprofile=newArray(totalprofilelength);
	totalprofile_counter=0;
	segment_starts =0;
	for (i = 0; i < xCA.length-1; i++) {
		makeLine(xCA[i], yCA[i], xCA[i+1], yCA[i+1]);
		tempProfile=getProfile();
		//plotlength =pow((xCA[i+1]-xCA[i]),2)+pow((yCA[i+1]-yCA[i]),2);
		//plotlength = pow(plotlength, 0.5);
		//print ("length="+ plotlength + " points = " +tempProfile.length); 
		for(j=0;j<tempProfile.length;j++)      {
			//totalprofile[segment_starts+j]=tempProfile[j];
			totalprofile[segment_starts+j]=tempProfile[j]*width;
			totalprofile_counter++;
		}
		segment_starts= totalprofile_counter;
		//print(i + ":"+ totalprofile_counter);
	}
	selectImage(kymoID);
	for(i=0; i<totalprofile.length; i++) setPixel(xCA[0]+i, framenum, totalprofile[i]);

	//if ( plot_switch) K_createThickProfilePlot(totalprofile, InteractiveRange_switch);
	//if (results_switch) output_results(totalprofile);
}








