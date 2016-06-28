 // *************  Multi-Cell Tracker 3D analysis *******************************************
//-  Author: Kota Miura (miura@embl.de) 
// Deviated from "Multi-Cell Tracker 3D" started 3D 040614
//	Macros for registering particles (cells) to Track Info window and
//	to retrieve data from the rack Info Window.

// 040825	4D sequence crawer.
// 040826 path assignment by interactive dialogue
//041016 Velocity Plotting Moved from main program

var RoiCount;
var celldetection_mode=4;	// only cross-correlation=1, center-of-mass=2, wand=3 particle track=4
var scanrange=10;
var zscanrange=2;
var speedfactor=1;	//speed factor = delta-t*micrometer/pixel
var deltaT=1;
var micromPpix=1.3;
var speedunit="pixels/frame";
var zframes=21;
var zframethickness=2.5;
var zfactor=1;
var space4substack=4;
//var savepath="C:\\import\\"
var pathname="C:\\import\\"
var paintR=255;
var paintG=0;
var paintB=0;


//********* global variable controller**********

// only cross-correlation=1, center-of-mass=2, wand=3, particle analysis=4
// particle analysis is recommended for good contrast target object.

macro "Set time interval and XY scale" {
	deltaT=getNumber("Time Interval (sec)?",deltaT);
	micromPpix=getNumber("Scale (micrometer per pixel)?",micromPpix);
	speedfactor=micromPpix/deltaT*60;
	speedunit="micormeter/min";
}

macro "Set Z frames and Z scale" {
	zframes=getNumber("Number of Frames in Z?",zframes);
	zframethickness=getNumber("Z  thickness (in micrometer)?",zframethickness);
	zfactor=zframethickness/micromPpix;
}


//macro "Set Save Path" {
//	savepath=getString("Save Path?",savepath);
//}

macro "Set Path (choose folder).." {
	SetpathFunc();
}
function SetpathFunc() {
	requires("1.32f");
	pathname=getDirectory("select a folder");
	op="saving Path set to "+pathname;	
	print(op);
}


macro "-"{}
macro "Set Paint Red" {
	paintR=255;
	paintG=0;
	paintB=0;
}
macro "Set paint Blue" {
	paintR=0;
	paintG=0;
	paintB=255;
}
macro "-"{}
macro "Go 4Dframe by 3D frame number [j]" {
	framenum3D=getNumber("3D framenumber?",1);
	framenum4D= zframes*framenum3D;
	op="slice="+framenum4D;	
	run("Set Slice...", op);
}

macro "proceed Z slices[u]" {
	for (i=0;i<zframes;i+=1) {
		run("Next Slice [>]");
	}
}

macro "back Z slices[y]" {
	for (i=0;i<zframes;i+=1) {
		run("Previous Slice [<]");
	}
}

//macro "Print Status in Log Window" {
//	kPrintStates();
//}

macro '-' {} 


macro "Save Coordinates as a table" {
	requires("1.31g");
	RoiID=getNumber("RoiID?",1);
	run("Clear Results");
	startframe=Return_ROI_startf(RoiID);
	endframe=Return_ROI_endf(RoiID);
	coordArraysize=endframe-startframe+1;
	restA=newArray(coordArraysize);
	resxA=newArray(coordArraysize);
	resyA=newArray(coordArraysize);
	reszA=newArray(coordArraysize);
	restoreCoordArray(RoiID,resxA,resyA,reszA);
	for(i=0;i<coordArraysize;i++){
		restA[i]=startframe*deltaT+i*deltaT;
	}
	run("Clear Results");
	SaveResultsCoreV2(RoiID,restA,resxA,resyA,reszA);
	selectWindow("Results");
	run("Text..."); // File>Save As>Text
}

macro "Save Coordinates as a table Multi" {
	requires("1.31g");
	CellNumber=getNumber("How many cells?",1);
	expnamestring=getString("Name of Experiment?","experiment");
	SetpathFunc();
	for(j=0;j<CellNumber;j++){
		RoiID=j+1;
		run("Clear Results");
		startframe=Return_ROI_startf(RoiID);
		endframe=Return_ROI_endf(RoiID);
		coordArraysize=endframe-startframe+1;
		restA=newArray(coordArraysize);
		resxA=newArray(coordArraysize);
		resyA=newArray(coordArraysize);
		reszA=newArray(coordArraysize);
		restoreCoordArray(RoiID,resxA,resyA,reszA);
		for(i=0;i<coordArraysize;i++){
			restA[i]=startframe*deltaT+i*deltaT;
		}
		run("Clear Results");
		SaveResultsCoreV2(RoiID,restA,resxA,resyA,reszA);
		selectWindow("Results");
		op="save="+pathname+expnamestring+(j+1)+".txt";
		run("Text...",op); // File>Save As>Text
	}
}


macro "-" {}


//====================ROI info I/O======================================

/first row: information on conditions //2nd row: x coordinates (results);
//3rd row: y coordinates (results); //4th row: z coordinates (results);
// for 3D //5th row: vacant

function Create_ROI_Recording_Frame() {
	run("New...", "name=Track_ROIinfo.tif type=16-bit fill=White width=300 height=200 slices=1");
}
function setpixel(InfXpos,InfYpos,pixvalue) {
	selectWindow("Track_ROIinfo.tif");
	setPixel(InfXpos,InfYpos,pixvalue);
}

function RegiROICore() {
	getBoundingRect(roix, roiy, roiwidth, roiheight);
	RoiID=getNumber("RoiID?",1);	
	RoiThres=getNumber("Threshold?",50);
	RoiStartFrame=getNumber("Start Frame?",1);
	RoiEndFrame=getNumber("End Frame?",10);

	currentImageID=getImageID();
	//CheckRoiInfoWin=isOpen("Track_ROIinfo.tif");
	if (!isOpen("Track_ROIinfo.tif")) {
		Create_ROI_Recording_Frame();
	}
	selectWindow("Track_ROIinfo.tif");
	currentInfoCol=(RoiID-1)*5;

	setpixel(0,currentInfoCol,roix);
	setpixel(1,currentInfoCol,roiy);
	setpixel(2,currentInfoCol,roiwidth);
	setpixel(3,currentInfoCol,roiheight);
	setpixel(4,currentInfoCol,RoiThres);
	setpixel(5,currentInfoCol,RoiStartFrame);
	setpixel(6,currentInfoCol,RoiEndFrame);
	for(i=0;i<RoiEndFrame-RoiStartFrame+1;i++) {		// for z-aray, put 1.
		setpixel(6,currentInfoCol+3,1);
	}
	op="RoiID"+RoiID+" registered.";
	print(op);
	selectImage(currentImageID);
}
macro "Register ROI [f5]" {
	RegiROICore();
}
function Return_ROI_threshold(RoiID) {
	currentImageID=getImageID();
	selectWindow("Track_ROIinfo.tif");
	currentInfoCol=(RoiID-1)*5;
	thres=getPixel(4,currentInfoCol);
	selectImage(currentImageID);
	return thres;
}
function Return_ROI_startf(RoiID) {
	currentImageID=getImageID();
	selectWindow("Track_ROIinfo.tif");
	currentInfoCol=(RoiID-1)*5;
	sf=getPixel(5,currentInfoCol);
	selectImage(currentImageID);
	return sf;
}

function Return_ROI_endf(RoiID) {
	currentImageID=getImageID();
	selectWindow("Track_ROIinfo.tif");
	currentInfoCol=(RoiID-1)*5;
	ef=getPixel(6,currentInfoCol);
	selectImage(currentImageID);
	return ef;
}

function restoreCoordArray(RoiID,xA,yA,zA) {
	currentImageID=getImageID();
	if (!isOpen("Track_ROIinfo.tif")) {
		showMessageWithCancel("Abort","Track_ROIinfo.tif must be opend!");
	}
	selectWindow("Track_ROIinfo.tif");

	currentInfoColx=(RoiID-1)*5+1;
	currentInfoColy=(RoiID-1)*5+2;
	currentInfoColz=(RoiID-1)*5+3;

	size=xA.length;
	for(i=0;i<size;i++) {
		xA[i]=getPixel(i,currentInfoColx);
		yA[i]=getPixel(i,currentInfoColy);
		zA[i]=getPixel(i,currentInfoColz);
	}	
	selectImage(currentImageID);
} 

function SaveResultsCoreV2(RoiID,restA,resxA,resyA,reszA) {
	row = 0;
	labelt="C"+RoiID+"_T";
	labelx="C"+RoiID+"_X";
	labely="C"+RoiID+"_Y";
	labelz="C"+RoiID+"_Z";
	for (row=0; row<resxA.length; row++) {
		setResult(labelt, row, restA[row]);
		setResult(labelx, row, resxA[row]);
		setResult(labely, row, resyA[row]);
		setResult(labelz, row, reszA[row]);
	}
	updateResults();
}

macro "Recreate ROI [f6]" {
	Recreate_ROI();
}

function Recreate_ROI() {
	if (!isOpen("Track_ROIinfo.tif")) {
		showMessage("error","You Need a ROI info window!");
	}
	else {
		RoiID=getNumber("RoiID?",1);
		Recreate_ROI_core(RoiID);
	}
}


function Recreate_ROI_core(RoiID) {
	currentImageID=getImageID();
	selectWindow("Track_ROIinfo.tif");
	currentInfoCol=(RoiID-1)*5;

	roix=getPixel(0,currentInfoCol);
	roiy=getPixel(1,currentInfoCol);
	roiwidth=getPixel(2,currentInfoCol);
	roiheight=getPixel(3,currentInfoCol);
	selectImage(currentImageID);
	makeRectangle(roix, roiy, roiwidth, roiheight);
}

macro "Recreate ROI and Go Slice [f7]" {
	Recreate_ROI_GoSlice();
}

function Recreate_ROI_GoSlice() {
	if (!isOpen("Track_ROIinfo.tif")) {
		showMessage("error","You Need a ROI info window!");
	}
	else {
		RoiID=getNumber("RoiID?",1);
		SliceNum=Return_ROI_startf(RoiID);
		currentImageID=getImageID();
		selectWindow("Track_ROIinfo.tif");
		currentInfoCol=(RoiID-1)*5;
		roix=getPixel(0,currentInfoCol);
		roiy=getPixel(1,currentInfoCol);
		roiwidth=getPixel(2,currentInfoCol);
		roiheight=getPixel(3,currentInfoCol);
		selectImage(currentImageID);
		op="slice="+SliceNum;
		run("Set Slice...", op);		
		makeRectangle(roix, roiy, roiwidth, roiheight);
	}
}


function kPrintROIInfo(RoiID) {
	print(" ");
	print("ROI info:id"+RoiID);
	print("threshold:"+Return_ROI_threshold(RoiID)+"     Start Frame:"+Return_ROI_startf(RoiID)+"     end frame:"+Return_ROI_endf(RoiID));
}

macro "Print ROI info" {
	if (!isOpen("Track_ROIinfo.tif")) {
		showMessage("error","You Need a ROI info window!");
	}
	else {	
		RoiID=getNumber("RoiID?",1);
		selectWindow("Track_ROIinfo.tif");
		kPrintROIInfo(RoiID);
	}
}
macro "-" {}

//**************************************************************************

macro "Draw a Track in a new Window" {
	StartRoiID=getNumber("start RoiID",1);
	//EndRoiID=getNumber("end RoiID",2);
	stackID=getImageID();
	makeAcopyFrame(1);
	DrawTrackAll(StartRoiID,StartRoiID,stackID)
	drawColorZ();
}

macro "Draw All Tracks in a new Window" {
	StartRoiID=getNumber("start RoiID",1);
	EndRoiID=getNumber("end RoiID",2);
	stackID=getImageID();
	makeAcopyFrame(1);
	DrawTrackAll(StartRoiID,EndRoiID,stackID)
	drawColorZ();
}

macro "Append Tracks to a Window" {
	StartRoiID=getNumber("start RoiID",1);
	EndRoiID=getNumber("end RoiID",2);
	stackID=getImageID();
	DrawTrackAll(StartRoiID,EndRoiID,stackID)
	//drawColorZ();
}

function DrawTrackAll(StartRoiID,EndRoiID,stackID) {
	trackframeID=getImageID();
	for(i=StartRoiID;i<EndRoiID+1;i++) {
		startframe=Return_ROI_startf(i);
		endframe=Return_ROI_endf(i);
		coordArraysize=endframe-startframe+1;
		resxA=newArray(coordArraysize);
		resyA=newArray(coordArraysize);
		reszA=newArray(coordArraysize);
		restoreCoordArray(i,resxA,resyA,reszA);
		drawtrackCore2(trackframeID,resxA,resyA,reszA);
	}
}

function drawtrackCore2(drawframeID,xpa,ypa,zpa) {
	selectImage(drawframeID);
	run("RGB Color");
	//setForegroundColor(TrackR,TrackG,TrackB);
	size=xpa.length-1;
	for(i=0;i<size;i++) {
		level=(zpa[i]+zpa[i+1])/2;
		TrackR=(255/zframes)*level;
		TrackG=abs((255/zframes)*level-50);
		TrackB=(255-(255/zframes)*level);		
		setColor(TrackR,TrackG,TrackB);
		xa=xpa[i];
		xb=xpa[i+1];
		ya=ypa[i];
		yb=ypa[i+1];
		drawLine(xa, ya, xb, yb);
	}
	//setForegroundColor(255, 255, 255);
}

macro "-"{}

function PlotTrackDynamic_stack(RoiID,stackID,paint) {
	selectImage(stackID);
	frames=nSlices;
	startframe=Return_ROI_startf(RoiID);
	endframe=Return_ROI_endf(RoiID);
	coordArraysize=endframe-startframe+1;
	resxA=newArray(coordArraysize);
	resyA=newArray(coordArraysize);
	reszA=newArray(coordArraysize);
	restoreCoordArray(RoiID,resxA,resyA,reszA);
	if (paint) {
		 run("RGB Color");
		setForegroundColor(paintR,paintG,paintB);
	}
	for(i=0;i<resxA.length;i++) {
		op="slice="+(startframe+i);
		run("Set Slice...", op);
		makeOval(resxA[i]-4,resyA[i]-4, 9, 9);
		wait(50);	
		if (paint) {
			makeOval(resxA[i]-1,resyA[i]-1, 3, 3);
			run("Fill", "slice");
		}
		wait(50);	
	}
	setForegroundColor(255,255,255);
}

macro "Plot dynamic Track in a Stack [f1]" {
	RoiID=getNumber("RoiID?",1);
	stackID=getImageID();
	PlotTrackDynamic_stack(RoiID,stackID,0);
}
macro "Plot dynamic paint Track in a Stack [f2]" {
	RoiID=getNumber("RoiID?",1);
	stackID=getImageID();
	PlotTrackDynamic_stack(RoiID,stackID,1);
}

macro "Plot dynamic paint Track in a Stack All" {
	sRoiID=getNumber("start RoiID?",1);
	eRoiID=getNumber("end RoiID?",2);
	stackID=getImageID();
	for(i=sRoiID;i<eRoiID+1;i++) {
		PlotTrackDynamic_stack(i,stackID,1);
	}
}

//********** Misc Utilities *******

function makeAcopyFrame(FrameNum) {
	op="slice="+FrameNum;
	run("Set Slice...", op);
	ww=getWidth();
	wh=getHeight();

	// Prepare the track plotting 
	run("Select All");
	run("Copy");
	//op="name=FirstImg type=8-bit fill=White width="+ww+" height="+wh+" slices=1";
	op="name=FirstImg type=RGB fill=White width="+ww+" height="+wh+" slices=1";
	run("New...", op);
	run("Paste");
}


//------------- Drawing Z scale bar ----------------------------------
function DrawZcodeBar() {
	ww=getWidth();
	wh=getHeight();
	xpos=ww-30;
	ypos=wh-60;	
	k=50;
	for(i=ypos;i<ypos+50;i++) {
		level=zframes/50*k;
		TrackR=(255/zframes)*level;
		TrackG=abs((255/zframes)*level-50);
		TrackB=(255-(255/zframes)*level);
		//setForegroundColor(TrackR, TrackG, TrackB);
		setColor(TrackR, TrackG, TrackB);
		drawLine(xpos, i, xpos+5, i);
		k-=1;		
	}
	updateDisplay();	
}

function labelZcodeBar() {
	setBackgroundColor(0, 0, 0);
	//setForegroundColor(255, 255, 255);
	setColor(255, 255, 255);
	ww=getWidth();
	wh=getHeight();
	//run("Colors...", "foreground=white background=black selection=yellow");
	xpos=ww-20;
	ypos=wh-10;
	stringinfo="1";	
	drawString(stringinfo, xpos, ypos);
	ypos=wh-60;	
	stringinfo=zframes;
	drawString(zframes, xpos, ypos);
}

//macro "testZcodeBar" {
function drawColorZ() {
	DrawZcodeBar(); 
	//wait(500);
	labelZcodeBar();
}	

//---------------- Z scale bar end---------------------------------------

//
macro "-"{}

//***************** Velocity Graph Plotting **************************
function returnAverageSpeed(xA,yA,zA) {
	size=xA.length;
	sigvel=0;
	for(i=0;i<size-1;i++) {
		sqv=pow(xA[i+1]-xA[i],2)+pow(yA[i+1]-yA[i],2)+pow((zA[i+1]-zA[i])*zfactor,2);
		vel=sqrt(sqv);
		vel*=speedfactor;
		sigvel+=vel;
	}
	avevel=sigvel/(size-1);
	return avevel;
}


function ReturnMaxOf(Aarray) {
	maxvalue=Aarray[0];
	size=Aarray.length;
	for(i=1;i<size;i++) {
		if (maxvalue<Aarray[i]) {
			maxvalue=Aarray[i];
		}
	}
	return maxvalue;
}
function PlotVelocityCore(RoiID,stackID) {
	startframe=Return_ROI_startf(RoiID);
	endframe=Return_ROI_endf(RoiID);
	coordArraysize=endframe-startframe+1;
	resxA=newArray(coordArraysize);
	resyA=newArray(coordArraysize);
	reszA=newArray(coordArraysize);
	restoreCoordArray(RoiID,resxA,resyA,reszA);
	VelA=newArray(coordArraysize-1);
	TimeA=newArray(coordArraysize-1);
	for(i=0;i<VelA.length;i++) {
		VelA[i]=sqrt(pow(resxA[i+1]-resxA[i],2)+pow(resyA[i+1]-resyA[i],2)+pow(zfactor*(reszA[i+1]-reszA[i]),2))*speedfactor;
		TimeA[i]=i*deltaT;
	}
	//AverageVelocity=returnAverageSpeed(resxA,resyA,reszA);
	AverageVelocity=findAVEofArray(VelA);	//returnAverage1array(VelA);
	maxvalue=ReturnMaxOf(VelA);
	title="Velocity (3D) of Cell"+RoiID;
	if (speedfactor==1) {
		xlabel="Time (frame)";
		ylabel="Velocity (pixels/frame)";
	} else {
		xlabel="Time (sec)";
		ylabel="Velocity (micormeter/min)";
	}
	Plot.create(title, xlabel,ylabel, TimeA, VelA);
	Plot.setLimits(0, TimeA.length*1.05*deltaT, 0, maxvalue*1.2);
	Plot.setColor("red");
	//ingraphtxt="Cell"+RoiID+" Average: "+AverageVelocity;
	ingraphtxt="Cell"+RoiID+" Average Speed("+speedunit+"): "+AverageVelocity;
//	Plot.setColor("black");
	Plot.addText(ingraphtxt, 0.1, 0.1);
	Plot.show();
	//ingraphtxt="Cell"+RoiID+" Average Speed("+speedunit+"): "+AverageVelocity;	
	kPrintStates(); 
	print(ingraphtxt);
//	print("  x,  y,  z");
//	for(i=0;i<resxA.length;i++) {
//		coordxy=""+resxA[i]+","+resyA[i]+","+reszA[i];
//		print(coordxy);
//	}
}

macro "Plot Velocity Time Course [g]" {
	RoiID=getNumber("RoiID?",1);
	stackID=getImageID();
	PlotVelocityCore(RoiID,stackID);
}


