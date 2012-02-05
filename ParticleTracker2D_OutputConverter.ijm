/* ParticleTracker2D_OutputConverter.ijm
Kota Miura, CMCI, EMBL Heidelberg 
contact: miura at embl dot de +49 6221 387 404

ParticleTracker2D output converter: converts results output of particleTracker plugin
http://weeman.inf.ethz.ch/particletracker/

081020 Converter parts only, copied from K_primodiumV2.ijm
081021 planned features
	- instantaneous velocity listings [pixels/frame]
	- graph displacement (with several averaging steps)
	- angle  [absolute, against a certain reference point]
081022 finishd the first version
081023 registration funciton added (for Jerome)
	
*/

var GPlotColor="Red";

/*
var rgb_r=255;
var rgb_g=0;
var rgb_b=0;
*/
function SetPickedColor() {
	if (GPlotColor=="Red") {
		rgb_r=255;
		rgb_g=0;
		rgb_b=0;
	}
	if (GPlotColor=="Green") {
		rgb_r=0;
		rgb_g=255;
		rgb_b=0;
	}
	if (GPlotColor=="Blue") {
		rgb_r=0;
		rgb_g=0;
		rgb_b=255;
	}
	if (GPlotColor=="White") {
		rgb_r=255;
		rgb_g=255;
		rgb_b=255;
	}
	if (GPlotColor=="Black") {
		rgb_r=0;
		rgb_g=0;
		rgb_b=0;
	}
	setColor(rgb_r,rgb_g,rgb_b);
	setForegroundColor(rgb_r,rgb_g,rgb_b);
}

//081020 copied from k_ParticleTrackerOutputConverter.ijm
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
// 081021 renamed from "Track Converter General'
macro "ParticleTracker Textfile Converter - Trackwise"{
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

//081020 copied from k_ParticleTrackerOutputConverter.ijm
// frame by frame converter
//input file: full report saved by ParticleTracker Plugin
// export (x, y) coordinates of dots in each frame detected by the particle tracker plugin. 
/* exported text is formatted as follows in case of 2D results:
frame	x		y		none-particle discrimination criteria
0	301.968719	232.164536	3.566766	
0	315.058167	229.136307	3.968908	
0	125.101028	235.868500	5.044083	
0	269.851807	251.980789	4.502931

in case of 3D
frame	x		y		z

 */
//070910
//081020 renamed
macro "ParticleTracker Textfile Converter - Framewise"{
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


function CommaEliminator(strval) {
	while (indexOf(strval, ",")>0) {
			delindex = indexOf(strval, ",");
			returnstr = substring(strval, 0, delindex) + substring(strval, delindex+1, lengthOf(strval));
			strval = returnstr ;
	}	 	
	return strval;
}





macro "-" {}

macro "Choose Color For Plotting..." {
	requires("1.34m");
	Dialog.create("Color Picker");
	Dialog.addChoice("Plot Color:", newArray("Red", "Blue", "Green", "White", "Black"));
 	Dialog.show();
	GPlotColor = Dialog.getChoice();
}
macro "-" {}



// not working somehow on 081020
macro "Load Track File to Results (trackwise)"{
 	print("\\Clear");
	run("Clear Results");
	tempstr = File.openAsString("");
	openedFile=File.name();
	print(openedFile);
	openedDirectory = File.directory;
//	Load2ResultsV2(openedDirectory, openedFile);
	Load2ResultsV3(openedDirectory, openedFile);
}

//081020 modifed
//081020 copied from k_ParticleTrackerOutputConverter.ijm
// can use lines=split(str,"\n") 
//070522 update to 
function Load2ResultsV2(openpath,openedFile) {
	fullpathname=openpath+openedFile;
	print(fullpathname);
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");
	start_Index=0;
	rowcounter = 0;
	//columnnumber = 4;
	//columnnumber = 5;
	for(i=0; i<lineA.length; i++) {
		linecontentA=split(lineA[i],"\t");
		//print(linecontentA.length);
		if (linecontentA.length>1) {
			setResult("TrackNo", rowcounter , linecontentA[0]);
			setResult("Frame", rowcounter , linecontentA[1]);
			setResult("x", rowcounter , linecontentA[3]);
			setResult("y", rowcounter , linecontentA[2]);
			setResult("Intensity", rowcounter , linecontentA[4]);
			rowcounter++;
		}
	} 
	updateResults();
}

//081022
function Load2ResultsV3(openpath,openedFile) {
	fullpathname=openpath+openedFile;
	print(fullpathname);
	tempstr = File.openAsString(fullpathname);
	linesA=split(tempstr,"\n");
	trajectoryCount=1;
	//f1 = File.open("converted.txt");
	rowcounter =0;
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
				//print(tempstr2);
				tempstr =""+trajectoryCount + "\t" + tempstr2;
				//print(CommaEliminator(tempstr));
				finalstr = CommaEliminator(tempstr);
				linecontentA = split(finalstr, "\t");
				if (linecontentA.length>1) {
					setResult("TrackNo", rowcounter , linecontentA[0]);
					setResult("Frame", rowcounter , linecontentA[1]);
					setResult("x", rowcounter , linecontentA[3]);
					setResult("y", rowcounter , linecontentA[2]);
					setResult("Intensity", rowcounter , linecontentA[4]);
					rowcounter++;
				}				
			} while (linesA[i]!="") 
			trajectoryCount++;
		}
	}
	updateResults();
}


function ReturnStartRow4ID(TrackID){
	for(i=0; i<nResults; i++){
		if (getResult("TrackNo", i) == TrackID) {
			return i;
		}
	}
}

function ReturnEndRow4ID(TrackID){
	for(i=ReturnStartRow4ID(TrackID); i<nResults; i++){
		if (getResult("TrackNo", i) != TrackID) return i-1;
	}
	return i-1; //this happens only at the last row (nResults-1);
}

/*
macro "testID"{
	print(ReturnStartRow4ID(113));
	print(ReturnEndRow4ID(113));
}
*/


//081020 use point picker to select a dot, then indicates the Particle ID
macro "... Get Particle ID" {
	getParticleID();
}

function getParticleID() {
	getSelectionBounds(xpos, ypos, width, height);
	currentSlice = getSliceNumber();
	if (nResults==0) exit("you must load data into results window first");
	tA = newArray(nResults);
	fA = newArray(nResults);
	xA = newArray(nResults);
	yA = newArray(nResults);
	for (i=0; i<nResults; i++) {
		tA[i] = getResult("TrackNo", i);
		fA[i] = getResult("Frame", i);
		xA[i] = getResult("x", i);
		yA[i] = getResult("y", i);
	}
	minimumDist =100;
	selectedID =0;
	selectedRow =0;
	selectedFrame =currentSlice -1;
	selectedX = 0;
	selectedY =0;
	for (i=0; i<xA.length; i++) {
		if (fA[i] == selectedFrame ) {
			currentdist = abs(xA[i] - xpos) + abs(yA[i]-ypos);
			if (currentdist < minimumDist) {
				minimumDist = currentdist;
				selectedTrackID = tA[i];
				selectedRow = i; 
				selectedX = xA[i];
				selectedY =yA[i];
			}
		}
	}
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("");
	print(leftPad(hour, 2)+":"+leftPad(minute, 2)+":"+leftPad(second, 2));
	print("Picked Position:"+xpos+", "+ ypos);
	print("TrackNo"+ selectedTrackID+ "  Frame"+selectedFrame + "  x= "+selectedX+" y="+selectedY);
	startrow=ReturnStartRow4ID(selectedTrackID);
	endrow=ReturnEndRow4ID(selectedTrackID);
	print("track start frame:"+getResult("Frame", startrow)+" end frame:"+getResult("Frame", endrow)+ " frame Length:" + endrow-startrow+1);
	return selectedRow;
}
//digits padding
function leftPad(n, width) {
    s =""+n;
    while (lengthOf(s)<width)
        s = "0"+s;
    return s;
}

macro "... Check a track By Point Picker [f2]" {
	TrackVisualzerPointPick(0, 0); 
}

macro "...... Plot a track By Point Picker" {
	TrackVisualzerPointPick(0, 1); 
}

function TrackVisualzerPointPick(paint, trace) {
	if ((selectionType()  != 10) && (selectionType()  != 1) ) exit("choose a dot using point picker");
	stackID=getImageID();	
	currentRow = getParticleID();
	TrackID = getResult("TrackNo", currentRow);	
 	//print("\\Clear");
	//run("Clear Results");
	PlotTrackDynamic_stack(stackID,TrackID, paint, trace);
}


macro "...Check a track By ID [f3]"{
	TrackVisualzer(0, 0); 
}

// user input of the ID
macro "...... Plot a track by ID" {
	TrackVisualzer(0, 1); 
}

//081020 largely modified, so that the track info is directly recovered from results window. 
function TrackVisualzer(paint, trace) {
	stackID=getImageID();	
	TrackID=getNumber("Track ID?",0);
 	//print("\\Clear");
	//run("Clear Results");
	PlotTrackDynamic_stack(stackID,TrackID, paint, trace);
}

function TrackExists(TrackID) {
	trackexists =0; 
	for(i=0; i<nResults; i++) if (getResult("TrackNo", i) == TrackID) return 1;
	return 0;
}

function returnNumberOfTracks() {
	trackcount=0;
	currenttrackNo=-1;
	for(i=0; i<nResults; i++) {
		if (getResult("TrackNo", i) != currenttrackNo) {
			currenttrackNo=getResult("TrackNo", i);
			trackcount++;
		}
	}
	return trackcount
}

macro "... Plot All Tracks" {
	NumberofTracks=returnNumberOfTracks();
	tracklistA=newArray(NumberofTracks);
	trackcount=0;
	currenttrackNo=-1;
	for(i=0; i<nResults; i++) {
		if (getResult("TrackNo", i) != currenttrackNo) {
			currenttrackNo=getResult("TrackNo", i);
			tracklistA[trackcount] = currenttrackNo;
			trackcount++;
		}
	}

	stackID=getImageID();	
	if (nSlices ==1) exit("Need an active window with image stack");
	currentcolor = GPlotColor;
	setBatchMode(true);
	for(i=0; i<tracklistA.length; i++) {
		GPlotColor="Red";
		//SetPickedColor();
		PlotTrackDynamic_stack(stackID,tracklistA[i], 0, 1);
	}	
	for(i=0; i<tracklistA.length; i++) {
		GPlotColor="Blue";
		//SetPickedColor();
		PlotTrackDynamic_stack(stackID,tracklistA[i], 1, 0);
	}	
	GPlotColor = currentcolor;
	setBatchMode("exit and display");
}

//081020 largely modified, so that the track info is directly recovered from results window. 
//070507 copied from tracking2Dv2b and modified. 
function PlotTrackDynamic_stack(stackID,TrackID, paint, trace) {
	//Load2Results(openedDirectory,openedFile);
	if (nResults ==0) exit("Need to load the tracks first");
	selectImage(stackID);
	if (TrackExists(TrackID)==0) exit("That trackID does not exists");

	frames=nSlices;
	if ((paint) || (trace)){
		run("RGB Color");
		SetPickedColor();
	}
	trackpointcounter =0;
	startrow = ReturnStartRow4ID(TrackID);
	endrow = ReturnEndRow4ID(TrackID);
	//SetPickedColor();
	for(i=startrow;i<(endrow+1);i++) {
		currenttrack = getResult("TrackNo", i);
		currentslice=getResult("Frame", i);
		currentX = round(parseFloat(getResult("x", i)));
		currentY = round(parseFloat(getResult("y", i)));
		currentInt = parseFloat(getResult( "Intensity", i));	
		setSlice(currentslice+1);
		if ((trace==0) && (paint==0)) {
			makeOval(currentX-4,currentY -4, 9, 9);
			wait(20);
		}	
		if (paint) {	//dots
			makeOval(currentX-1,currentY -1, 3, 3);
			run("Fill", "slice");
		}
		if (trace) {
			if (trackpointcounter >0){
				for (j=startrow+1; j<=i; j++) {
					x1 =  round(parseFloat(getResult("x", j-1)));
					y1 =  round(parseFloat(getResult( "y", j-1)));
					x2 =  round(parseFloat(getResult( "x", j)));
					y2 =  round(parseFloat(getResult( "y", j)));
					drawLine(x1, y1, x2, y2);
				}
			}
				//if (i==nResults-1) {
				//	setForegroundColor(255,255,255);
				//	setFont("SansSerif", 10);
				//	trackID=substring(trackname, 2, lengthOf(trackname));
				//	drawString(trackID, currentX , currentY);
				//}
		} //else wait(20);
		trackpointcounter +=1;
	}
	setForegroundColor(255,255,255);
	print("TrackID"+TrackID+" Frames: "+ trackpointcounter);
}

macro "... Print All Track Information for Excel" {
	NumberofTracks=returnNumberOfTracks();
	tracklistA=newArray(NumberofTracks);
	trackcount=0;
	currenttrackNo=-1;
	for(i=0; i<nResults; i++) {
		if (getResult("TrackNo", i) != currenttrackNo) {
			currenttrackNo=getResult("TrackNo", i);
			tracklistA[trackcount] = currenttrackNo;
			trackcount++;
		}
	}
	print("******* TRACK INFORMATION ******* ");
	print("TrackID\t startframe\t endframe\t Frames\t AveInt\t AveVel");
	for(i=0; i<tracklistA.length; i++) {
		printTrackinfo(tracklistA[i]) ;
	}
	print("******* END ******* ");
		
}

function printTrackinfo(TrackID) {
	if (TrackExists(TrackID)==0) exit("That trackID does not exists");
	startrow= ReturnStartRow4ID(TrackID);
	endrow = ReturnEndRow4ID(TrackID);
	framelength =getResult("Frame", endrow) - getResult("Frame", startrow) +1;
	AverageIntensity = ReturnAverageInt(TrackID, 0);
	Averagevelocity = ReturnAverageVel(TrackID, 0, 1);
	//print("TrackID\t"+TrackID+"\t startframe\t"+getResult("Frame", startrow) + "\t endframe\t"+ getResult("Frame", endrow) + "\tFrames\t" + framelength + "\t AveInt\t"+AverageIntensity + "\tAveVel\t" + Averagevelocity);
	print(TrackID+"\t"+getResult("Frame", startrow) + "\t"+ getResult("Frame", endrow) + "\t" + framelength + "\t"+AverageIntensity + "\t" + Averagevelocity);

}

macro "-"{}

function ReturnAverageVel(TrackID, printresult, boxwidth) {
	if (nResults ==0) exit("Need to load the tracks first");
	if (TrackExists(TrackID)==0) exit("That trackID does not exists");

	startrow = ReturnStartRow4ID(TrackID);
	endrow = ReturnEndRow4ID(TrackID);
	framelength = getResult("Frame", endrow) - getResult("Frame", startrow) +1;
	if ((framelength - boxwidth) <2) return NaN;
	fA = newArray(framelength);
	xA = newArray(framelength);
	yA = newArray(framelength);
	vA = newArray(framelength- boxwidth);
	fgA = newArray(framelength- boxwidth);
	for(i=startrow;i<(endrow+1);i++) {
		fA[i-startrow] =getResult( "Frame", i);
		xA[i-startrow] = parseFloat(getResult( "x", i));
		yA[i-startrow] = parseFloat(getResult( "x", i));
		if (i>(startrow + boxwidth -1)) vA[i-startrow - boxwidth] = (returnDistance2D(xA[i-startrow- boxwidth] , yA[i-startrow- boxwidth],  xA[i-startrow] , yA[i-startrow])) / (fA[i-startrow] - fA[i-startrow- boxwidth]) ;		
	}
	sumV =0;
	for (i=0; i<vA.length; i++) sumV += vA[i];
	aveV = sumV / vA.length;
	if (printresult) print("TrackID"+TrackID+" Average velocity: "+ aveV + " boxwidth:"+  boxwidth);
	return aveV;
}
/*
macro "test V" {
	print(ReturnAverageVel(70, 1, 3));
}
*/
function ReturnAverageInt(TrackID, printresult) {
	if (nResults ==0) exit("Need to load the tracks first");
	if (TrackExists(TrackID)==0) exit("That trackID does not exists");
	trackpointcounter =0;
	startrow = ReturnStartRow4ID(TrackID);
	endrow = ReturnEndRow4ID(TrackID);
	for(i=startrow;i<(endrow+1);i++) {
		currentInt = parseFloat(getResult( "Intensity", i));
		sumint += currentInt;	
		trackpointcounter +=1;
	}
	if (printresult) print("TrackID"+TrackID+" Average Intensity: "+ (sumint/trackpointcounter ));
	return (sumint/trackpointcounter );
}



macro "Filter ... by Intensity" {
	IntensityThreshold = getNumber("Intensity Threshold? (darker ones will be deleted)", 10);
	NumberofTracks=returnNumberOfTracks();
	tracklistA=newArray(NumberofTracks);
	trackcount=0;
	currenttrackNo=-1;
	for(i=0; i<nResults; i++) {
		if (getResult("TrackNo", i) != currenttrackNo) {
			currenttrackNo=getResult("TrackNo", i);
			tracklistA[trackcount] = currenttrackNo;
			trackcount++;
		}
	}
		
	for(i=0; i<tracklistA.length; i++) {
		AverageInt = ReturnAverageInt(tracklistA[i], 1);
		if (AverageInt < IntensityThreshold ) {
			TrackDeleter(tracklistA[i]);
			print("--> TrackID"+tracklistA[i]+" deleted from result table :average intensity="+AverageInt);
		}
	}	
}


macro "Filter ... by frame length" {
	FrameLenThreshold = getNumber("Minimum Frame Length? (shorter ones will be deleted)", 3);
	NumberofTracks=returnNumberOfTracks();
	tracklistA=newArray(NumberofTracks);
	trackcount=0;
	currenttrackNo=-1;
	for(i=0; i<nResults; i++) {	//store trackIDs in an array
		if (getResult("TrackNo", i) != currenttrackNo) {
			currenttrackNo=getResult("TrackNo", i);
			tracklistA[trackcount] = currenttrackNo;
			trackcount++;
		}
	}
		
	for(i=0; i<tracklistA.length; i++) {
		startrow= ReturnStartRow4ID(tracklistA[i]);
		endrow = ReturnEndRow4ID(tracklistA[i]);
		framelength =getResult("Frame", endrow) - getResult("Frame", startrow) +1;

		if (framelength < FrameLenThreshold ) {
			TrackDeleter(tracklistA[i]);
			print("--> TrackID"+tracklistA[i]+" deleted from result table :frame length = "+framelength +" frames");
		}
	}	
}

macro "-"{}

macro "Delete a Track from Results (Trackwise) [f5]" {
	if (nResults ==0) exit("Results must be loaded");
	deleteTrackID = getNumber("TrackID to delete", 1);
	if (TrackExists(deleteTrackID )==0) exit("That trackID does not exists");
	TrackDeleter(deleteTrackID);
}

function TrackDeleter(deleteTrackID) {
	tA = newArray(nResults);
	fA = newArray(nResults);
	xA = newArray(nResults);
	yA = newArray(nResults);
	intA = newArray(nResults);

	for (i=0; i<nResults; i++) {
		tA[i]=getResult("TrackNo", i);
		fA[i]=getResult("Frame", i);
		xA[i]=getResult("x", i);
		yA[i]=getResult("y", i);
		intA[i]=getResult("Intensity", i);
	}
	run("Clear Results");
	rowcounter=0;
	for (i=0; i<tA.length; i++){
		if(tA[i] != deleteTrackID) {
			setResult("TrackNo", rowcounter , tA[i]);
			setResult("Frame", rowcounter , fA[i]);
			setResult("x", rowcounter , xA[i]);
			setResult("y", rowcounter , yA[i]);
			setResult("Intensity", rowcounter , intA[i]);
			rowcounter ++;
		}
	}
	print("TrackID"+deleteTrackID +" deleted");
	updateResults();
}


// change, so that the position within the results window also changes. 
macro "Merge Tracks in Results (Trackwise)" {
	if (nResults ==0) exit("Results must be loaded");
	TrackID1=1; 
	TrackID2=2;
 	Dialog.create("Merge Tracks");
	Dialog.addNumber("TrackID1:", TrackID1);
	Dialog.addNumber("TrackID2:", TrackID2);
  	Dialog.show();
	TrackID1= Dialog.getNumber();
	TrackID2= Dialog.getNumber();
	if (TrackExists(TrackID1)==0) exit("That trackID 1 does not exist");
	if (TrackExists(TrackID2)==0) exit("That trackID 2 does not exist");
	if (TrackID2<TrackID1) {
		tempID = TrackID1;
		TrackID1 = TrackID2;
		TrackID2 = tempID;
	}
	
	T1end = ReturnEndRow4ID(TrackID1);
	T2start = ReturnStartRow4ID(TrackID2);
	T2end = ReturnEndRow4ID(TrackID2);
	overlap = 0;
	if (getResult("Frame",T2start) <= getResult("Frame",T1end)) {
		overlap = getResult("Frame",T1end) - getResult("Frame",T2start) +1;
		print("TrackID2:"+TrackID2+ " starts before TrackID1:"+TrackID1 +" starts: overlap"+overlap);
		//exit("TrackID2:"+TrackID2+ " starts before TrackID1:"+TrackID1 +" starts");
	}
	
	TrackMerginginColumn("TrackNo", T1end, T2start, T2end, overlap, 0);
	TrackMerginginColumn("Frame", T1end, T2start, T2end, overlap, 0);
	TrackMerginginColumn("x", T1end, T2start, T2end, overlap, 1);
	TrackMerginginColumn("y", T1end, T2start, T2end, overlap, 1);
	TrackMerginginColumn("Intensity", T1end, T2start, T2end, overlap, 1);

	for(i=0; i<nResults; i++){
		if (getResult("TrackNo", i)==TrackID2) setResult("TrackNo", i, TrackID1);
	}

	print("Track Merging: track"+TrackID1+" and track"+TrackID2+ " --> Track"+TrackID1);
	updateResults();
	
	// clean up results window
	newtA = newArray(nResults-overlap);
	newfA = newArray(nResults-overlap);
	newxA = newArray(nResults-overlap);
	newyA = newArray(nResults-overlap);
	newintA = newArray(nResults-overlap);

	for(i=0; i<newtA.length; i++) newtA[i] = getResult("TrackNo", i);
	for(i=0; i<newfA.length; i++) newfA[i] = getResult("Frame", i);
	for(i=0; i<newxA.length; i++) newxA[i] = getResult("x", i);
	for(i=0; i<newyA.length; i++) newyA[i] = getResult("y", i);
	for(i=0; i<newintA.length; i++) newintA[i] = getResult("Intensity", i);
	run("Clear Results");
	for(i=0; i<newtA.length; i++)  setResult("TrackNo", i, newtA[i]);
	for(i=0; i<newfA.length; i++)  setResult("Frame", i, newfA[i]);
	for(i=0; i<newxA.length; i++)  setResult("x", i, newxA[i]);
	for(i=0; i<newyA.length; i++)  setResult("y", i, newyA[i]);
	for(i=0; i<newintA.length; i++)  setResult("Intensity", i, newintA[i]);
	updateResults();
}

// in normal case, trackID1 info is used for the overlapping part and trackID2 info is discarded
// when average ==1 trackID1 info and trackID2 info will be averaged at the overlapping part
function TrackMerginginColumn(columnSt, T1end, T2start, T2end, overlap, average){
	pointnum =nResults;
	aA = newArray(T1end+1);		//trackID1
	bA = newArray(T2start - T1end -1);
	cA = newArray(T2end - T2start +1); //trackID2
	ctrunkA = newArray(T2end - T2start +1-overlap); //trackID2 overlapped part truncated
	dA = newArray(nResults - T2end - 1);
	pointnum =nResults-overlap;
	for(i=0; i<nResults; i++){
		if (i<(T1end+1)) aA[i] = getResult(columnSt, i);
 		if ((i>(T1end)) && (i<(T2start))) bA[i-(T1end+1)] = getResult(columnSt, i);
 		if ((i>=(T2start)) && (i<(T2end+1))) cA[i-T2start] = getResult(columnSt, i);
		if (i>T2end) dA[i-T2end-1] = getResult(columnSt, i);
	}
	if (average==1) for(i=0; i<overlap; i++) aA[i + aA.length-overlap] = (aA[i + aA.length-overlap] + cA[i])/2;
	for (i=0; i<ctrunkA.length; i++) ctrunkA[i] = cA[i+overlap];
	//for (i=0; i<ctrunkA.length; i++) print(ctrunkA[i]);
	
	//run("Clear Results");
	for(i=0; i<pointnum; i++) {
		if (i<aA.length) setResult(columnSt, i , aA[i]);
			//if ((i>=aA.length) && (i<(aA.length+cA.length))) setResult(columnSt, i , cA[i-aA.length]);
		if ((i>=aA.length) && (i<(aA.length+ctrunkA.length))) setResult(columnSt, i , ctrunkA[i-aA.length]);
		if ((i>=(aA.length+ctrunkA.length)) && (i<(aA.length+ctrunkA.length+bA.length))) setResult(columnSt, i , bA[i-aA.length-ctrunkA.length]);
		if (i>=(aA.length+ctrunkA.length+bA.length)) setResult(columnSt, i , dA[i-aA.length-ctrunkA.length-bA.length]);

	}
	for(i=pointnum; i<pointnum+overlap; i++) setResult(columnSt, i , -10000);
}





/*
macro "Test Merge"{
	TrackMerginginColumn("TrackNo", 5211, 5217, 5223);
}
*/

macro "Guess Successive TrackID (strict)" {
	NextTrackSearchCore(1);
}

macro "Guess Successive TrackID (loose) [f8]" {
	NextTrackSearchCore(0);
}


function NextTrackSearchCore(strictness){

	if (nResults ==0) exit("Load tracks in Results window");
	searchframes = 4;
	searchdistance = 10;
 	Dialog.create("Next Track Search");
	Dialog.addNumber("Frame Range for searching", searchframes);
	Dialog.addNumber("Distance Range for searching", searchdistance );
	Dialog.addChoice("Search Mode", newArray("Use Current Point", "Specify TrackID"));
  	Dialog.show();
	searchframes = Dialog.getNumber();
	searchdistance = Dialog.getNumber();
	searchmode = Dialog.getChoice();
	if (searchmode == "Use Current Point") {
		if ((selectionType()  != 10) && (selectionType()  != 1) ) exit("choose a dot using point picker");
		getSelectionBounds(xpos, ypos, width, height);
		currentFrame = getSliceNumber()-1;
	} else { //get TrackID
		trackID = getNumber("TrackID?", 1);
		endrow =ReturnEndRow4ID(trackID);
		currentFrame = getResult("Frame", endrow);
		xpos = getResult("x", endrow);
		ypos = getResult("y", endrow);
	}
	print("");
	print("--- Candidates for the Next Track ---");
	print("from frame"+ currentFrame + "@" +xpos+","+ypos);
	if (searchmode == "Specify TrackID") print("assignment: trackID"+trackID);
	if (strictness==1) {
		print(">>strict search: next one should be the starting point");
	} else {
		print(">>loose search: next track could be in the middle");	
	}
	isnext =0;
	for (i=0; i<nResults; i++) {
		if (strictness ==1) {
			if ((getResult("Frame", i)>=currentFrame) && (getResult("Frame", i)<(currentFrame+searchframes))) {
				if (ReturnStartRow4ID(getResult("TrackNo", i)) == i) {
					x2 = getResult("x", i);
					y2 = getResult("y", i);
					distance =returnDistance2D(xpos, ypos,  x2, y2);
					print("frame accepted ID:"+getResult("TrackNo", i));
					print("-distance="+distance);
					if (distance < searchdistance ) {
						print("TrackID:"+getResult("TrackNo", i)+ "  Frame:+"+(getResult("Frame", i)-currentFrame) + "Distance:"+returnDistance2D(xpos, ypos,  x2, y2));
						isnext =1;		
					}
				}
			}
		} else {
			if ((getResult("Frame", i)>=currentFrame) && (getResult("Frame", i)<(currentFrame+searchframes))) {
				x2 = getResult("x", i);
				y2 = getResult("y", i);
				distance =returnDistance2D(xpos, ypos,  x2, y2);
				//print("frame accepted ID:"+getResult("TrackNo", i));
				//print("-distance="+distance);
				if (distance < searchdistance ) {
					print("TrackID:"+getResult("TrackNo", i)+ "    Frame:+"+(getResult("Frame", i)-currentFrame)); 
					print("--> Distance:"+returnDistance2D(xpos, ypos,  x2, y2));
					isnext =1;		
				}
			}			
			
		}
	}
	if (isnext==0) print("...no candidates: maybe increase the search range");
}

function returnDistance2D(x1, y1,  x2, y2){
	dist2D = pow( (pow((x1-x2), 2) + pow((y1-y2), 2)  ), 0.5);
	return dist2D;
}

macro "-"{}
//081023
macro "XY corrector Reference Particel" {
	TrackID = getNumber("Which Track is the Reference?", 1);
	stackID = getImageID();

	XYcorrectbyID(stackID, "XY", TrackID );
}


//081023 XYZcorrectbyID downgraded to XY corrector
// registration of the whole image using one tracked point a
function XYcorrectbyID(stackID, dimension, TrackID ){
	
	selectImage(stackID);
	if (bitDepth>16) exit("image should be 8 or 16 bit");

	currentBitDepth = bitDepth;
	imw = getWidth();
	imh = getHeight();
 	tnum = nSlices;

	currentfA = newArray(nSlices);
	currentxA = newArray(nSlices);
	currentyA = newArray(nSlices);
	shiftxA = newArray(nSlices);
	shiftyA = newArray(nSlices);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
	}

	framecount = 0;
	trackexists = 0;

	Tstart = ReturnStartRow4ID(TrackID);
	Tend = ReturnEndRow4ID(TrackID);

	for (k=Tstart; k<Tend+1 ; k++) {
		currentfA[k-Tstart]= getResult("Frame", k);
		currentxA[k-Tstart]= parseFloat(getResult("x", k));
		currentyA[k-Tstart]= parseFloat(getResult("y", k));

		shiftxA[k-Tstart] = currentxA[k-Tstart] - currentxA[0];
		shiftyA[k-Tstart] = currentyA[k-Tstart] - currentyA[0];

		print(currentfA[k-Tstart]+ ":dx " + shiftxA[k-Tstart] + ", dy " + shiftyA[k-Tstart] );
	}
	selectImage(stackID);

	setBatchMode(true);

	newimgOP = ""+currentBitDepth + "-bit Black";
	newImage("xycorrected", newimgOP , imw, imh, tnum);
	xyCorjID = getImageID;	
	for(i=0; i<tnum;i++) {
		selectImage(stackID);		
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(xyCorjID);	
		setSlice(i+1);
		makeRectangle(-1*shiftxA[i], -1*shiftyA[i], imw, imh);
		run("Paste");
	}	
	setBatchMode("exit and display");
}


/* ****************************************************commented out 081021
macro "-" {}

//081020 copied from k_ParticleTrackerOutputConverter.ijm
//070911 works with the output textfile by "Track Converter General"
//080307 should be able to use this also for 3D results, without z plotting. 

macro "Plot All Tracks 2D (trackwise file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,0, 1);
}


//070911 works with the output textfile by "Track Converter General"
//080307 should be able to use this also for 3D results, without z plotting. 

macro "Plot All Particles 2D 2D   (trackwise file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,1, 0);
}

//070507 copied from tracking2Dv2b and modified. 
//070911 renamed and modified for direct selection of the track file. 
// track file in the format of exproted by Converter in this macro. 

function PlotTrackDynamic_stackDirect(stackID,paint, trace) {
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

	if ((paint) || (trace)){
		 run("RGB Color");
		SetPickedColor();		
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
						SetPickedColor();	
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
//081020 copied from k_ParticleTrackerOutputConverter.ijm
macro "... track filter  (trackwise file)" {
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

macro "-"{}

//081020 copied from k_ParticleTrackerOutputConverter.ijm
// uses out put of Frame Wise particle Positions Converter
//works on 2D  xy projection

//081020 copied from k_ParticleTrackerOutputConverter.ijm
macro "Frame wise info dot plot (Framewise file)" {
	stackID = getImageID();
	 PlotTrackDynamic_stackFrameWiseInfo(stackID, 1);
}


//071024
function PlotTrackDynamic_stackFrameWiseInfo(stackID, zscale) {
	selectImage(stackID);
	frames=nSlices;
	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);
	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
	}

	run("RGB Color");
	SetPickedColor();
	//setForegroundColor(rgb_r,rgb_g,rgb_b);		

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = linecontentA[0];
			currentxA[k] = linecontentA[2];
			currentyA[k] = linecontentA[1];
		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
		} 
	}
	for  (k=0; k<lineA.length; k++) {
		if (currentfA[k]>-1){
			print(""+k+":"+currentfA[k] + ":" + currentxA[k] + "," + currentyA[k] );
			setSlice(currentfA[k]+1);
			if (zscale!=1) {
				//tempy = currentyA[k] * zscale+ zscale/2 -1;
				fillOval(currentxA[k]-1, currentyA[k]- 1, 3, 3); 	//dots
			} else {
				fillOval(currentxA[k]-1,currentyA[k] -1, 3, 3); 	//dots
			}
		}
	}
	setForegroundColor(255,255,255);

	selectImage(stackID);
}

// Check the intensity in the Sequence and rejects particles with dark mean intensity in the surrounding. 
//the aim is to remove the noise derived particles. 

//081020 copied from k_ParticleTrackerOutputConverter.ijm
macro "Framewise Info filter"{
	stackID = getImageID();
	thrlow = getNumber("minimum intensity?", 80);	
	FrameWiseInfo_IntensityFilter(stackID, thrlow);
}

//071024
function FrameWiseInfo_IntensityFilter(stackID, thrlow) {
 	print("\\Clear");
	roisize =9;
	roihalf = floor(roisize/2);
	selectImage(stackID);
	frames=nSlices;
	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);

	filteredfA = newArray(lineA.length);
	filteredxA = newArray(lineA.length);
	filteredyA = newArray(lineA.length);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
	}
	//print("-3	-3	-3 "+ lineA.length);
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = linecontentA[0];
			currentxA[k] = linecontentA[2];
			currentyA[k] = linecontentA[1];
		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
		} 
	}
	for  (k=0; k<lineA.length; k++) {
		selectImage(stackID);
		if (currentfA[k]>-1) {
			//print(""+k+":"+currentfA[k] + ":" + currentxA[k] + "," + currentyA[k] );
			setSlice(currentfA[k]+1);
			roix =currentxA[k];
			roiy =currentyA[k];
			roix -= roihalf;
			roiy -=roihalf;
			if (roix<0) roix=0;
			if (roiy<0) roiy=0;
			if (roix>getWidth()-1) roix=getWidth()-1;
			if (roiy>getHeight()-1) roiy=getHeight()-1;
			makeRectangle(roix , roiy, roisize , roisize );
			getRawStatistics(nPixels, mean); //, min, max, std, histogram);
			if (mean>thrlow) {
				filteredfA[k] = currentfA[k];
				filteredxA[k] = currentyA[k];	//becarful of orde x and y
				filteredyA[k] = currentxA[k];
				//print()
			} else {
				filteredfA[k] = -1;
				filteredxA[k] = -1;
				filteredyA[k] = -1;
			}
		} else {
			filteredfA[k] = -1;
			filteredxA[k] = -1;
			filteredyA[k] = -1;
		}
	}

	for  (k=0; k<lineA.length; k++) {
		if (filteredfA[k]>-1) {
			tempstr = ""+ filteredfA[k] + "\t" + filteredxA[k] + "\t"+ filteredyA[k]; 
			print(tempstr);
		}
	}
	selectWindow("Log");
	saveAs("text");
	selectImage(stackID);
}


*/



