/* K_particletracker3DConverter.ijm

converter and analyzer for the output of ParticleTracker3D plugin putputs
Kota Miura, CMCI EMBL

080308 Copied and edited some of functions from K_particletrackeroutputconverter.ijm

*/


macro "x-projection" {
	imw = getWidth();
	imh = getHeight();
	znum = getNumber("z slices?", 15);
	zscale = getNumber("z scaling?", 10);

	//znum = 15;
	tnum = nSlices/znum;
	originalID = getImageID();
	newImage("xprojection", "8-bit Black", imw, znum, tnum);
	xprojID =  getImageID();
	setBatchMode(true);
	xprojectionCore(originalID, xprojID , znum);
	selectImage(xprojID);
	//op = "width="+imw+" height="+Gzscaler*znum;
	op = "width="+imw+" height="+zscale*znum;
	run("Size...", op);
	setBatchMode("exit and display");
	 
}

//slice 1 comes at the bottom of the xz plane. 
function xprojectionCore(originalID, xprojID , znum) {
	selectImage(originalID);
	imw = getWidth();
	imh = getHeight();
	tnum = nSlices/znum;
	newImage("temp_timepoint", "8-bit White", imw, imh, znum);
	tempimgID = getImageID();

	for(j=0; j<tnum; j++) {
		for(i=0; i<znum; i++) {
			selectImage(originalID);
			setSlice(j * znum + i + 1);
			run("Select All");
			run("Copy");
			selectImage(tempimgID);
			setSlice(i + 1);
			run("Paste");				
		}
		selectImage(tempimgID);
		run("3D Project...", 
			"projection=[Brightest Point] axis=X-Axis slice=1 initial=90 total=1 rotation=1 lower=1 upper=255 opacity=0 surface=100 interior=50");

		setSlice(1);
		sliceypos = imh/2 + 1 - floor(znum/2);
		makeRectangle(0, sliceypos, imh, znum);
		run("Copy");
		close();
		selectImage(xprojID );	
		setSlice(j+1);
		run("Paste");
	}	
	selectImage(tempimgID);	
	close();
}

macro "-"{}


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

/* in case of 3D data (works with 3D also):
//	line1: track number
//	line2: frame number
//	line3: x position
//	line4: y position
//	line5: z position
//	line6: intensity moments of order 0
//	line7: intensity moments of order 2
//	line8: non-particle discrimination criteria
*/
macro "Track Converter General"{
 	 print("\\Clear");
	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	//tempstr = File.openAsString("");
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
	print(fullpathname);
}

//checks how many frames did the tracking was done. If the track is less than input value, then the 
//track is discarded

macro "... track filter by length" {
	tracklengthmin = getNumber("Minimum tracklength?", 3);
	FilterTracksLength(tracklengthmin -1);
}

function FilterTracksLength(tracklengthTH) {
 	print("\\Clear");
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

macro "... filter tracks by length and intensity using 3D-t stack" {
	tracklengthmin = getNumber("Minimum tracklength?", 4);
	thrlow = getNumber("lower intensity threshold?", 15);

	FilterTracksLengthInt(tracklengthmin -1, thrlow , 1);
}

macro "... filter tracks by length and intensity using 2D-t stack" {
	tracklengthmin = getNumber("Minimum tracklength?", 4);
	thrlow = getNumber("lower intensity threshold?", 15);

	FilterTracksLengthInt(tracklengthmin -1, thrlow , 0);
}

//out put order: trackID- frame-x-y-z
function FilterTracksLengthInt(tracklengthTH, thrlow , stack3D) {
 	 print("\\Clear");
	maxtracklength = 1000;
	stackID=getImageID();
	roisize =9;
	roihalf = floor(roisize/2);
	selectImage(stackID);
	frames=nSlices;
	zdepth = 1;
	if (stack3D == 1) {
		zdepth = getNumber("How many slices in Z?", 15);
		timepoints = frames/zdepth;
		if ((frames%zdepth) != 0) exit("probably wrong z slice number or wrong stack");
		oldparticlecountA = newArray(timepoints); 
		particlecountA = newArray(timepoints); 
	} else {
		oldparticlecountA = newArray(frames);
		particlecountA = newArray(frames);
	}


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

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);
	currentzA = newArray(lineA.length);

	meanintA = newArray(lineA.length);

	filteredfA = newArray(lineA.length);
	filteredxA = newArray(lineA.length);
	filteredyA = newArray(lineA.length);
	filteredzA = newArray(lineA.length);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
		meanintA[i] = -1;
	}
	//print("-3	-3	-3 "+ lineA.length);
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
/*			currentfA[k] = linecontentA[0];
			currentxA[k] = linecontentA[2];
			currentyA[k] = linecontentA[1];
			currentzA[k] = linecontentA[3];
*/
			currentfA[k] = linecontentA[1];
			currentxA[k] = linecontentA[3];
			currentyA[k] = linecontentA[2];
			currentzA[k] = linecontentA[4];


		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
			currentzA[k] = -1;
		} 
	}

	tracknum = 1;
	framecount = 0;
	newlinecount =0;
	intensitylow =0;

	afterfilteringtracknumber=0; 
	for (k=0; k<lineA.length; k++) {
		do {
			linecontentA=split(lineA[k],"\t");
			if (linecontentA.length>1) {
				//print(tracknum+ "-"+currentslice + ":" + currentX + "," + currentY );
				if (stack3D == 1) {
					//setSlice(currentfA[k]*zdepth+round(currentzA[k]));
					setSlice(currentfA[k]*zdepth+round(currentzA[k])+1);
				} else {
					 setSlice(currentfA[k]+1);
				}
				oldparticlecountA[currentfA[k]] +=1; 
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
				meanintA[k] =  mean;
				if (mean>thrlow) {
					filteredfA[k] = currentfA[k];
					filteredxA[k] = currentyA[k];	//becarful of orde x and y
					filteredyA[k] = currentxA[k];
					filteredzA[k] = currentzA[k];
					//particlecountA[filteredfA[k]] +=1; 
					//print()
				} else {
					intensitylow = 1; 
					filteredfA[k] = -2;
					filteredxA[k] = -2;
					filteredyA[k] = -2;
					filteredzA[k] = -2;
				}

				if (framecount ==0) currenttrack = linecontentA[0];
				//currentLineA[framecount] = lineA[k];
				currentLineA[framecount] = ""+currenttrack + "\t"+filteredfA[k]+"\t"+filteredxA[k]+"\t"+filteredyA[k]+"\t"+filteredzA[k]+"\t"+meanintA[k];
		 		framecount++;
				k++;
			} 

		} while (linecontentA.length>1);

		if ((framecount>tracklengthTH) && (intensitylow ==0)) {
			for(i =0; i<framecount; i++) print(currentLineA[i]);
			print(currenttrack);
			afterfilteringtracknumber+=1;			
		} 

		intensitylow =0;
		framecount =0;
		tracknum+=1;
	}

	selectWindow("Log");
	saveAs("text");
 	 print("\\Clear");
	print("original:"+tracknum + "tracks --> filtered: "+afterfilteringtracknumber+" tracks");
}

macro "count Tracks in Converted File" {
	TrackNumberCounter();
}

function TrackNumberCounter() {
	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");
	tracknum =0;
	framecount = 0;
	maxframe = 0;
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			if (parseInt(linecontentA[1]) > maxframe ) maxframe  = linecontentA[1];
		}
	}
	FramewiseParticleNumA=newArray(maxframe+1);

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length<=1) {
			tracknum+=1;
		} else {
			FramewiseParticleNumA[parseInt(linecontentA[1])] +=1;
		}
	}
	print(fullpathname);
	print("Tracks: "+ tracknum);
	for (k=0; k< FramewiseParticleNumA.length; k++) print ("frame " + k + ": " +FramewiseParticleNumA[k]+ " particles");
}

macro "-" {}

//070911 works with the output textfile by "Track Converter General"
//080307 should be able to use this also for 3D results, without z plotting. 

macro "Dynamic track plotting 2DXY RED (use converted file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,0, 1, "red", "xy");
}

macro "Dynamic track plotting 2DXY BLUE (use converted file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,0, 1, "blue", "xy");
}


//070911 works with the output textfile by "Track Converter General"
//080307 should be able to use this also for 3D results, without z plotting. 
macro "Dynamic spot plotting 2DXY  (use converted file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,1, 0, "red", "xy");
}

macro "-"{}
macro "Dynamic track plotting 2DXZ RED (use converted file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,0, 1, "red", "xz");
}

macro "Dynamic track plotting 2DXZ BLUE (use converted file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,0, 1, "blue", "xz");
}


macro "Dynamic spot plotting 2DXZ RED (use converted file)" {
	stackID = getImageID();
	PlotTrackDynamic_stackDirect(stackID,1, 0, "red", "xz");
}

//070507 copied from tracking2Dv2b and modified. 
//070911 renamed and modified for direct selection of the track file. 
// track file in the format of exproted by Converter in this macro. 

function PlotTrackDynamic_stackDirect(stackID,paint, trace, color, dimension) {
	selectImage(stackID);
	frames=nSlices;
	if (dimension =="xz") zscale = getNumber("z scale?", 10);

	currentxA = newArray(nSlices);
	currentyA = newArray(nSlices);
	currentzA = newArray(nSlices);
	currentfA = newArray(nSlices);
	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
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
	
	wh = getHeight();
	for (k=0; k<lineA.length; k++) {
		do {
			linecontentA=split(lineA[k],"\t");
			if (linecontentA.length>1) {
				tracknum = linecontentA[0];
				currentslice = linecontentA[1];
				currentX = linecontentA[3];
				currentY = linecontentA[2];
				currentZ = linecontentA[4];

				print(tracknum+ "-"+currentslice + ":x " + currentX + ", y " + currentY + ", z " + currentZ);
				currentfA[framecount] = currentslice;
				currentxA[framecount] = currentX;
				currentyA[framecount] = currentY;
				currentzA[framecount] = currentZ;
		 		framecount++;
				k++;
			} 

		} while (linecontentA.length>1);

		for(plotloop =0; plotloop<framecount; plotloop++) { 
			setSlice(currentfA[plotloop]+1);
			if ((trace==0) && (paint==0)){
				if (dimensiion =="xy") {
					makeOval(currentxA[plotloop]-4,currentyA[plotloop] -4, 9, 9);
				} else {
					zposition = wh - ( zscale * (parseFloat(currentzA[plotloop])+1));
					makeOval(currentxA[plotloop]-4,zposition -4, 9, 9);
				}
				wait(20);
			}	
			if (paint) {
				if (dimension =="xy") {
					fillOval(currentxA[plotloop]-1,currentyA[plotloop] -1, 3, 3); 	//dots
				} else {
					zposition = wh - ( zscale * (parseFloat(currentzA[plotloop])+1));
					fillOval(currentxA[plotloop]-1,zposition -1, 3, 3);
				}
			}
			if (trace) {
				if (plotloop>0) 	{
					for (j=1; j<=plotloop; j++) {
						setColor(rgb_r,rgb_g,rgb_b);	
						if (dimension =="xy") {
							drawLine(currentxA[j-1], currentyA[j-1], currentxA[j], currentyA[j]);
						} else {
							zposition1 = wh - ( zscale * (parseFloat(currentzA[j])+1));
							zposition0 = wh - ( zscale * (parseFloat(currentzA[j-1])+1));
							//print(currentxA[j-1]+", "+zposition0+", "+currentxA[j]+", "+zposition1);
							drawLine(currentxA[j-1], zposition0, currentxA[j], zposition1);
						}
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

macro "-" {}

var G_TrackfileFullPath = "D:\People\Tomo\080311trial\G2G10track2_L2th15.txt";
macro "Set Track File"{
	G_TrackfileFullPath= File.openDialog("Select a track File");
	//openedDirectory = File.getParent(fullpathname );
	//openedFile = File.getName(fullpathname );
	//tempstr = File.openAsString(fullpathname);
	print(G_TrackfileFullPath);
}

var Gplayspeed = 20;
macro "Set Play Speed"{
	Gplayspeed=getNumber("Pay frame rate", Gplayspeed);
	print(Gplayspeed);
}



// file must be set before execution
macro "Show Track 2DXY (use converted file) [F1]" {
	stackID = getImageID();
	particleID = getNumber("particle ID", 0);
	ShowTrackwiID(stackID,"xy", particleID);
}

macro "Show Track 2DXZ (use converted file)" {
	stackID = getImageID();
	particleID = getNumber("particle ID", 0);
	ShowTrackwiID(stackID,"xz", particleID);
}

//070507 copied from tracking2Dv2b and modified. 
//070911 renamed and modified for direct selection of the track file. 
// track file in the format of exproted by Converter in this macro. 

function ShowTrackwiID(stackID, dimension, particleID) {
	selectImage(stackID);
	frames=nSlices;
	if (dimension =="xz") zscale = getNumber("z scale?", 10);

	currentxA = newArray(nSlices);
	currentyA = newArray(nSlices);
	currentzA = newArray(nSlices);
	currentfA = newArray(nSlices);
	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
	}
	//fullpathname = File.openDialog("Select a track File");
	//openedDirectory = File.getParent(fullpathname );
	//openedFile = File.getName(fullpathname );
	//tempstr = File.openAsString(fullpathname);
	tempstr = File.openAsString(G_TrackfileFullPath);

	lineA=split(tempstr,"\n");

//	tracknum = 1;
	framecount = 0;
	trackexists = 0;
	wh = getHeight();

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if ((linecontentA.length>1) && (parseInt(linecontentA[0])==particleID)) {
				tracknum = linecontentA[0];
				currentslice = linecontentA[1];
				currentX = linecontentA[3];
				currentY = linecontentA[2];
				currentZ = linecontentA[4];

				print(tracknum+ "-"+currentslice + ":x " + currentX + ", y " + currentY + ", z " + currentZ);
				currentfA[framecount] = currentslice;
				currentxA[framecount] = currentX;
				currentyA[framecount] = currentY;
				currentzA[framecount] = currentZ;
		 		framecount++;
		} 
//		framecount =0;
//		tracknum+=1;
	}
	selectImage(stackID);

	for(plotloop =0; plotloop<framecount; plotloop++) { 
		setSlice(currentfA[plotloop]+1);
		if (dimension =="xy") {
			makeOval(currentxA[plotloop]-4,currentyA[plotloop] -4, 9, 9);
		} else {
			zposition = wh - ( zscale * (parseFloat(currentzA[plotloop])+1));
			makeOval(currentxA[plotloop]-4,zposition -4, 9, 9);
		}
		wait(Gplayspeed);
	}			

}

macro "-"{}


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
0	301.968719	232.164536	3.566766	
0	315.058167	229.136307	3.968908	
0	125.101028	235.868500	5.044083	
0	269.851807	251.980789	4.502931

 */
//070910
macro "Frame Wise particle Positions Converter"{
 	 print("\\Clear");
	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	//tempstr = File.openAsString("");
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

	print(fullpathname);
}



function CommaEliminator(strval) {
	while (indexOf(strval, ",")>0) {
			delindex = indexOf(strval, ",");
			returnstr = substring(strval, 0, delindex) + substring(strval, delindex+1, lengthOf(strval));
			strval = returnstr ;
	}	 	
	return strval;
}


// Check the intensity in the Sequence and rejects particles with dark mean intensity in the surrounding. 
//the aim is to remove the noise derived particles. 
macro "... Framewise Info filter 3D using projection stack"{
	stackID = getImageID();
	thrlow = getNumber("minimum intensity?", 80);	
	FrameWiseInfo_IntensityFilter(stackID, thrlow, 0);
}

macro "... Framewise Info filter 3D using 4D stack"{
	stackID = getImageID();
	thrlow = getNumber("minimum intensity?", 80);	
	FrameWiseInfo_IntensityFilter(stackID, thrlow, 1);
}

//071024
//080306 modified for 3D 
function FrameWiseInfo_IntensityFilter(stackID, thrlow, stack3D) {
 	print("\\Clear");
	roisize =3;
	roihalf = floor(roisize/2);
	selectImage(stackID);
	frames=nSlices;
	zdepth = 1;
	if (stack3D == 1) {
		zdepth = getNumber("How many slices in Z?", 15);
		timepoints = frames/zdepth;
		if ((frames%zdepth) != 0) exit("probably wrong z slice number or wrong stack");
		oldparticlecountA = newArray(timepoints); 
		particlecountA = newArray(timepoints); 
	} else {
		oldparticlecountA = newArray(frames);
		particlecountA = newArray(frames);
	}
	fullpathname = File.openDialog("Select a frame-wise track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);
	currentzA = newArray(lineA.length);

	filteredfA = newArray(lineA.length);
	filteredxA = newArray(lineA.length);
	filteredyA = newArray(lineA.length);
	filteredzA = newArray(lineA.length);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
	}
	//print("-3	-3	-3 "+ lineA.length);
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = linecontentA[0];
			currentxA[k] = linecontentA[2];
			currentyA[k] = linecontentA[1];
			currentzA[k] = linecontentA[3];

		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
			currentzA[k] = -1;
		} 
	}
	for  (k=0; k<lineA.length; k++) {
		selectImage(stackID);
		if (currentfA[k]>-1) {
			//print(""+k+":"+currentfA[k] + ":" + currentxA[k] + "," + currentyA[k] );
			//setSlice(currentfA[k]+1);
			if (stack3D == 1) {
				//setSlice(currentfA[k]*zdepth+round(currentzA[k]));
				setSlice(currentfA[k]*zdepth+round(currentzA[k])+1);
			} else {
				 setSlice(currentfA[k]+1);
			}
			oldparticlecountA[currentfA[k]] +=1; 
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
				filteredzA[k] = currentzA[k];
				particlecountA[filteredfA[k]] +=1; 
				//print()
			} else {
				filteredfA[k] = -1;
				filteredxA[k] = -1;
				filteredyA[k] = -1;
				filteredzA[k] = -1;

			}
		} else {
			filteredfA[k] = -1;
			filteredxA[k] = -1;
			filteredyA[k] = -1;
			filteredzA[k] = -1;

		}
	}

	for  (k=0; k<lineA.length; k++) {
		if (filteredfA[k]>-1) {
			tempstr = ""+ filteredfA[k] + "\t" + filteredxA[k] + "\t"+ filteredyA[k]+"\t"+ filteredzA[k]; 
			print(tempstr);
		}
	}
	selectWindow("Log");
	saveAs("text");
 	print("\\Clear");
	for (i=0; i<particlecountA.length; i++) print("frame"+i+": "+oldparticlecountA[i]+" -> "+particlecountA[i]+" particles");
	selectImage(stackID);
}


macro "... Framewise 4D stack spot finder"{
	stackID = getImageID();
	FrameWiseInfo_spotParticle4D(stackID);
}

function FrameWiseInfo_spotParticle4D(stackID) {
 	print("\\Clear");
	zdepth = getNumber("How many slices in Z?", 15);
	particlenumber = getNumber("particleID?", 10);
	roisize =9;
	roihalf = floor(roisize/2);
	selectImage(stackID);
	frames=nSlices;
	fullpathname = File.openDialog("Select a frame-wise track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);
	currentzA = newArray(lineA.length);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
	}
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = linecontentA[0];
			currentxA[k] = linecontentA[2];
			currentyA[k] = linecontentA[1];
			currentzA[k] = linecontentA[3];

		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
			currentzA[k] = -1;
		} 
	}
	selectImage(stackID);
	if (currentfA[particlenumber ]>-1) {
		//setSlice(currentfA[particlenumber]*zdepth+round(currentzA[particlenumber]));
		setSlice(currentfA[particlenumber]*zdepth+round(currentzA[particlenumber])+1);

		roix =currentxA[particlenumber];
		roiy =currentyA[particlenumber];
		roix -= roihalf;
		roiy -=roihalf;
		if (roix<0) roix=0;
		if (roiy<0) roiy=0;
		if (roix>getWidth()-1) roix=getWidth()-1;
		if (roiy>getHeight()-1) roiy=getHeight()-1;
		makeRectangle(roix , roiy, roisize , roisize );
		getRawStatistics(nPixels, mean); //, min, max, std, histogram);
		print("particle:"+ particlenumber + " mean int="+mean);
		print(""+particlenumber +":"+currentfA[particlenumber ] + ":" + currentxA[particlenumber ] + "," + currentyA[particlenumber ]+"," + currentzA[particlenumber ] );

	} else {
		exit("vacant line, no particle");
	}
}

//080311
macro "count particle Framewise Info"{
	FrameWiseInfo_PrtclCounter();
}

//080311
function FrameWiseInfo_PrtclCounter() {
 	//print("\\Clear");
	particlecountA = newArray(10000);

	fullpathname = File.openDialog("Select a frame-wise track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);
	currentzA = newArray(lineA.length);

	for (i=0; i<particlecountA.length; i++) particlecountA[i] = -1;
	for (i=0; i<currentfA.length; i++) currentfA[i] = -1;

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = linecontentA[0];
		} else {
			currentfA[k] = -1;
		} 
	}
	for  (k=0; k<lineA.length; k++) {
		if (currentfA[k]>-1) particlecountA[currentfA[k]] +=1; 
	}
	print(fullpathname);
	i = 0;
	while (particlecountA[i]>-1) {
		print("frame"+i+": "+particlecountA[i]+" particles");
		i++;
	}
}

//********************

macro "-"{}

// uses out put of Frame Wise particle Positions Converter
//works on 2D  xy projection
macro "Frame wise info dot plot 2D...red" {
	stackID = getImageID();
	 PlotTrackDynamic_stackFrameWiseInfo(stackID, "red", 1);
}

macro "......................................  green" {
	stackID = getImageID();
	 PlotTrackDynamic_stackFrameWiseInfo(stackID, "green", 1);
}

macro "......................................  blue" {
	stackID = getImageID();
	 PlotTrackDynamic_stackFrameWiseInfo(stackID, "blue", 1);
}

//works on 2D  xz projection
macro "Frame wise info dot plot 2D10xz red" {
	stackID = getImageID();
	 PlotTrackDynamic_stackFrameWiseInfo(stackID, "red", 10);
}

macro "Frame wise info dot plot 2D10xz blue" {
	stackID = getImageID();
	 PlotTrackDynamic_stackFrameWiseInfo(stackID, "blue", 10);
}


//071024
function PlotTrackDynamic_stackFrameWiseInfo(stackID, color, zscale) {
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
	currentzA = newArray(lineA.length);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;

	}

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

	if (color=="green") {
		rgb_r=0;
		rgb_g=255;
		rgb_b=0;
	}

	 run("RGB Color");
	setColor(rgb_r,rgb_g,rgb_b);
	//setForegroundColor(rgb_r,rgb_g,rgb_b);		

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = parseFloat(linecontentA[0]);
			currentxA[k] = parseFloat(linecontentA[2]);
			currentyA[k] = parseFloat(linecontentA[1]);
			currentzA[k] = parseFloat(linecontentA[3]);

		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
			currentzA[k] = -1;

		} 
	}
	wh = getHeight();

	for  (k=0; k<lineA.length; k++) {
		if (currentfA[k]>-1){
			print(""+k+":"+currentfA[k] + ":" + currentxA[k] + "," + currentyA[k] + "," + currentzA[k] );
			setSlice(currentfA[k]+1);
			if (zscale!=1) {
				zposition = wh - ( zscale * (currentzA[k]+1));
				fillOval(currentxA[k]-1, zposition, 3, 3); 	//dots
			} else {
				fillOval(currentxA[k]-1,currentyA[k] -1, 3, 3); 	//dots
			}
		}
	}
	setForegroundColor(255,255,255);

	selectImage(stackID);
}

macro "-" {}

//080309
macro "Framewise info Plot Dots in XY and XZ(10x)"{
	zscale = 10;
	zslices = getNumber("zslices?", 15);
	stack4DID=getImageID();
	imw = getWidth();
	op = "group="+zslices+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	xyprojID = getImageID();
	rename("zprojection");


	selectImage(stack4DID);
	tnum = nSlices/zslices ;
	newImage("xprojection", "8-bit Black", imw , zslices , tnum);
	xprojID =  getImageID();
	setBatchMode(true);
	xprojectionCore(stack4DID, xprojID , zslices );
	selectImage(xprojID);
	//op = "width="+imw+" height="+Gzscaler*znum;
	op = "width="+imw+" height="+zscale*zslices ;
	run("Size...", op);
	setBatchMode("exit and display");

	selectImage(xyprojID);
	xyname = getTitle();
	PlotTrackDynamic_stackFrameWiseInfo(xyprojID, "blue", 1);
	PlotTrackDynamic_stackFrameWiseInfo(xyprojID, "red", 1);

	selectImage(xprojID);
	xzname = getTitle();
	PlotTrackDynamic_stackFrameWiseInfo(xprojID, "blue", zscale );
	PlotTrackDynamic_stackFrameWiseInfo(xprojID, "red", zscale );

	op = "stack1="+xyname +" stack2="+xzname +" combine";
	run("Stack Combiner", op);
}

macro "-"{}

macro "Frame wise info dot plot 3D...red" {
	stackID = getImageID();
	 PlotParticle4Dstack(stackID, "red", 1);
}

macro "Frame wise info dot plot 3D...green" {
	stackID = getImageID();
	 PlotParticle4Dstack(stackID, "green", 1);
}

macro "Frame wise info dot plot 3D...blue" {
	stackID = getImageID();
	 PlotParticle4Dstack(stackID, "blue", 1);
}


macro "Frame wise info dot plot 3D...white" {
	stackID = getImageID();
	 PlotParticle4Dstack(stackID, "white", 1);
}


//080308
//draws on 3D-t stack
function PlotParticle4Dstack(stackID, color, zscale) {
	selectImage(stackID);
	frames=nSlices;

	zdepth = getNumber("How many slices in Z?", 15);
	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);
	currentzA = newArray(lineA.length);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
	}

	if (color =="white") {
		rgb_r=255;
		rgb_g=255;
		rgb_b=255;
	} else {
		 run("RGB Color");

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

		if (color=="green") {
			rgb_r=0;
			rgb_g=255;
			rgb_b=0;
		}
	}

	setColor(rgb_r,rgb_g,rgb_b);
	//setForegroundColor(rgb_r,rgb_g,rgb_b);		

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = parseInt(linecontentA[0]);
			currentxA[k] = round( parseFloat(linecontentA[2]));
			currentyA[k] = round( parseFloat(linecontentA[1]));
			currentzA[k] = round( parseFloat(linecontentA[3]));

		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
			currentzA[k] = -1;

		} 
	}
	for  (k=0; k<lineA.length; k++) {
		if (currentfA[k]>-1){
			print(""+k+":"+currentfA[k] + ":" + currentxA[k] + "," + currentyA[k] + "," + currentzA[k] );
			//setSlice(currentfA[k]+1);
			setSlice(currentfA[k]*zdepth+round(currentzA[k])+1);
			fillOval(currentxA[k]-1,currentyA[k] -1, 3, 3); 	//dots
		}
	}
	setForegroundColor(255,255,255);

	selectImage(stackID);
}

macro "-"{}

var Gtitle = "win1";
var Rtitle = "win2";

// not completed yet 080311
macro "Channel Merging" {
	twoImageChoice();
	selectWindow(Gtitle);
	gid= getImageID();	
	selectWindow(Rtitle);
	rid= getImageID();	
	
	ww = getWidth();
	wh = getHeight();
	total = nSlices;
	total2 = nSlices *2;
	newImage("erged", "8-bit Black", ww , wh , total2);
	mergeID = getImageID();
	setBatchMode(true);
	for (i=0; i<total; i++) {
		selectImage(gid);
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(mergeID);
		setSlice(i*2+1);
		run("Paste");		
		i++;
		selectImage(rid);
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(mergeID);
		setSlice(i*2+2);
		run("Paste");		
	}	
	setBatchMode("exit and display");

}






function twoImageChoice() {
	imgnum=Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("select two images");
	//Dialog.addNumber("number1:", 0);
 	//Dialog.addNumber("number2:", 0);
	Dialog.addChoice("Ch Red", wintitleA);
	Dialog.addChoice("Ch Green", wintitleA);
 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 = Dialog.getNumber();;
 	Gtitle = Dialog.getChoice();
	Rtitle = Dialog.getChoice();
	print(Gtitle + Rtitle);
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
			print(i);
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


macro "-"{}

// to measure the average position of detected particles in "framewise" format and 
/ prints out as a text file. 
macro "xyz average position printer" {
	FrameWiseInfo_averagePosition() ;

}

function FrameWiseInfo_averagePosition() {
 	print("\\Clear");
//	zdepth = getNumber("How many slices in Z?", 15);
	frames = getNumber("How many time frames?", 10);

//	timepoints = frames/zdepth;
//	if ((frames%zdepth) != 0) exit("probably wrong z slice number or wrong stack");
//	oldparticlecountA = newArray(timepoints); 
//	particlecountA = newArray(timepoints); 

	fullpathname = File.openDialog("Select a frame-wise track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(frames);
	currentxA = newArray(frames);
	currentyA = newArray(frames);
	currentzA = newArray(frames);

	avefA = newArray(frames);
	avexA = newArray(frames);
	aveyA = newArray(frames);
	avezA = newArray(frames);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
	}
	
	//add up framenumbers, x, y, z;
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			cf = parseInt(linecontentA[0]);
			currentfA[cf] +=1;
			currentxA[cf] +=parseInt(linecontentA[1]);
			currentyA[cf] +=parseInt(linecontentA[2]);
			currentzA[cf] +=parseInt(linecontentA[3]);
		}
	}
	for (k=0; k< frames; k++) {
		avexA[k] = currentxA[k] / currentfA[k];
		aveyA[k] = currentyA[k] / currentfA[k];
		avezA[k] = currentzA[k] / currentfA[k];
			tempstr = ""+k+"\t"+ currentfA[k] + "\t" + avexA[k] + "\t"+ aveyA[k]+"\t"+ avezA[k]; 
			print(tempstr);
	}

	selectWindow("Log");
	saveAs("text");
 	print("\\Clear");
}


//correct the xy shifting of xyz-t stack. 
// using threshold and particle analysis. No input of tracked or framewise text. 
macro "xy systematic fluctuation corrector"{
	znum=15;
	originalID = getImageID();
	if (((nSlices/znum) - floor(nSlices/znum)) !=0) exit("wrong stack??");
	thlow = getNumber("threshold low?", 45); //45; // threshold lower value for the initial particle detection. (particles larger than 50 pixels area)
	print(((nSlices/znum) - floor(nSlices/znum)));
	op = "group="+znum+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	zprojID = getImageID();
	xycorrector(originalID, zprojID, znum, thlow);
}

function xycorrector(originalID, zprojID, znum, thlow){

	setBatchMode(true);
	selectImage(zprojID);
	imw = getWidth();
	imh = getHeight();
 	tnum = nSlices;
	//setAutoThreshold();
	setThreshold(thlow, 255);		//lower threshold value is better
	run("Set Measurements...", "area mean centroid center integrated slice redirect=None decimal=1");
	run("Analyze Particles...", "size=50-Infinity circularity=0.00-1.00 show=Outlines display exclude clear stack");
	slicenA= newArray(nResults);
	xA= newArray(nResults);
	yA= newArray(nResults);
	particlecountA = newArray(tnum );
	xaveA= newArray(tnum );
	yaveA= newArray(tnum );
	xshiftA= newArray(tnum );
	yshiftA= newArray(tnum );
	for (i = 0; i<nResults; i++) {
		slicenA[i] = getResult("Slice", i);
		xA[i] = getResult("XM", i);
		yA[i] = getResult("YM", i);
	}
	for (i = 0; i<slicenA.length; i++) {
		xaveA[slicenA[i]-1] += xA[i];			
		yaveA[slicenA[i]-1] += yA[i];
		particlecountA[slicenA[i]-1] +=1; 			
	}
	for (i = 0; i<particlecountA.length; i++) {
		xaveA[i] /=particlecountA[i];
		yaveA[i] /=particlecountA[i];
	}
	for (i = 0; i<xshiftA.length; i++) {
		if (i==0) {
			xshiftA[i] =0;
			yshiftA[i] =0;
		} else {
//			xshiftA[i] = round(xaveA[i] - xaveA[i-1]+xshiftA[i-1]);
//			yshiftA[i] = round(yaveA[i] - yaveA[i-1]+yshiftA[i-1]);
			xshiftA[i] = xaveA[i] - xaveA[i-1]+xshiftA[i-1];	//actally same as the method subtracting the first frame
			yshiftA[i] = yaveA[i] - yaveA[i-1]+yshiftA[i-1];
//			xshiftA[i] = xaveA[i] - xaveA[i-1];
//			yshiftA[i] = yaveA[i] - yaveA[i-1];
//			xshiftA[i] = xaveA[i] - xaveA[0];
//			yshiftA[i] = yaveA[i] - yaveA[0];
		}
		print("t:" + i + " x:" + xshiftA[i] + " y:"+yshiftA[i]);
	}
	newImage("xycorrectedZproj", "8-bit Black", imw, imh, tnum);
	zproCorjID = getImageID;	
	for(i=0; i<tnum;i++) {
		selectImage(zprojID);		
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(zproCorjID);	
		setSlice(i+1);
		makeRectangle(-1*xshiftA[i], -1*yshiftA[i], imw, imh);
		run("Paste");
	}	
	newImage("xycorrected", "8-bit Black", imw, imh, tnum*znum);
	xycorID=getImageID();
	for(i=0; i<tnum;i++) {
		for(j=0; j<znum;j++) {
			selectImage(originalID);
			setSlice(i*znum+j+1);
			run("Select All");
			run("Copy");			
			selectImage(xycorID);
			setSlice(i*znum+j+1);
			makeRectangle(-1*xshiftA[i], -1*yshiftA[i], imw, imh);
			run("Paste");	
		}
	}
	setBatchMode("exit and display");

}

// using threshold and particle analysis. No input of tracked or framewise text. 
macro "xy systematic fluctuation print text"{
	znum=15;
	originalID = getImageID();
	if (((nSlices/znum) - floor(nSlices/znum)) !=0) exit("wrong stack??");
	thlow = getNumber("threshold low?", 45); //45; // threshold lower value for the initial particle detection. (particles larger than 50 pixels area)
	print(((nSlices/znum) - floor(nSlices/znum)));
	op = "group="+znum+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	zprojID = getImageID();
	xyshiftPrint(originalID, zprojID, znum, thlow);
}

//080311
function xyshiftPrint(originalID, zprojID, znum, thlow){
	 	print("\\Clear");
	setBatchMode(true);
	selectImage(zprojID);
	imw = getWidth();
	imh = getHeight();
 	tnum = nSlices;
	//setAutoThreshold();
	setThreshold(thlow, 255);		//lower threshold value is better
	run("Set Measurements...", "area mean centroid center integrated slice redirect=None decimal=1");
	run("Analyze Particles...", "size=50-Infinity circularity=0.00-1.00 show=Outlines display exclude clear stack");
	slicenA= newArray(nResults);
	xA= newArray(nResults);
	yA= newArray(nResults);
	particlecountA = newArray(tnum );
	xaveA= newArray(tnum );
	yaveA= newArray(tnum );
	xshiftA= newArray(tnum );
	yshiftA= newArray(tnum );
	for (i = 0; i<nResults; i++) {
		slicenA[i] = getResult("Slice", i);
		xA[i] = getResult("XM", i);
		yA[i] = getResult("YM", i);
	}
	for (i = 0; i<slicenA.length; i++) {
		xaveA[slicenA[i]-1] += xA[i];			
		yaveA[slicenA[i]-1] += yA[i];
		particlecountA[slicenA[i]-1] +=1; 			
	}
	for (i = 0; i<particlecountA.length; i++) {
		xaveA[i] /=particlecountA[i];
		yaveA[i] /=particlecountA[i];
	}
	for (i = 0; i<xshiftA.length; i++) {
		if (i==0) {
			xshiftA[i] =0;
			yshiftA[i] =0;
		} else {
//			xshiftA[i] = round(xaveA[i] - xaveA[i-1]+xshiftA[i-1]);
//			yshiftA[i] = round(yaveA[i] - yaveA[i-1]+yshiftA[i-1]);
			xshiftA[i] = xaveA[i] - xaveA[i-1]+xshiftA[i-1];	//actally same as the method subtracting the first frame
			yshiftA[i] = yaveA[i] - yaveA[i-1]+yshiftA[i-1];
//			xshiftA[i] = xaveA[i] - xaveA[i-1];
//			yshiftA[i] = yaveA[i] - yaveA[i-1];
//			xshiftA[i] = xaveA[i] - xaveA[0];
//			yshiftA[i] = yaveA[i] - yaveA[0];
		}
		//print("" + i + "\t" + xshiftA[i] + "\t"+yshiftA[i]);
		print("" + i + "\t" +"0" + "\t"+xaveA[i] + "\t"+yaveA[i]+ "\t"+"0");	// first 0: dummy for number of counts, second 0: dummy for the z position

	}
	setBatchMode("exit and display");
	selectWindow("Log");
	saveAs("text");
 	print("\\Clear");
}

// using the file exported by "xyz average position printer" to correct for the systematic fluctuation
//uses frame-wise tracks. 
macro "xy systematic fluctuation corrector text input"{
	znum=15;
	originalID = getImageID();
	if (((nSlices/znum) - floor(nSlices/znum)) !=0) exit("wrong stack??");
	op = "group="+znum+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	zprojID = getImageID();
	xycorrectorTXT(originalID, zprojID, znum);
}

function xycorrectorTXT(originalID, zprojID, znum){

	fullpathname = File.openDialog("Select a frame-wise track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	setBatchMode(true);
	selectImage(zprojID);
	imw = getWidth();
	imh = getHeight();
 	tnum = nSlices;

	frameA = newArray(tnum );
	xaveA= newArray(tnum );
	yaveA= newArray(tnum );
	zaveA= newArray(tnum );

	xshiftA= newArray(tnum );
	yshiftA= newArray(tnum );
	zshiftA= newArray(tnum );


// reading coordinates from text file. 
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		cf = parseInt(linecontentA[0]);
		frameA[k] =cf;
		xaveA[cf] =parseInt(linecontentA[2]);
		yaveA[cf] =parseInt(linecontentA[3]);
		zaveA[cf] =parseInt(linecontentA[4]);
	}

	for (i = 0; i<xshiftA.length; i++) {
		if (i==0) {
			xshiftA[i] =0;
			yshiftA[i] =0;
		} else {
			xshiftA[i] = xaveA[i] - xaveA[i-1]+xshiftA[i-1];
			yshiftA[i] = yaveA[i] - yaveA[i-1]+yshiftA[i-1];
//			xshiftA[i] = xaveA[i] - xaveA[0];
//			yshiftA[i] = yaveA[i] - yaveA[0];
		}
		print("t:" + i + " x:" + xshiftA[i] + " y:"+yshiftA[i]);
	}
	newImage("xycorrectedZproj", "8-bit Black", imw, imh, tnum);
	zproCorjID = getImageID;	
	for(i=0; i<tnum;i++) {
		selectImage(zprojID);		
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(zproCorjID);	
		setSlice(i+1);
		makeRectangle(-1*xshiftA[i], -1*yshiftA[i], imw, imh);
		run("Paste");
	}	
	newImage("xycorrected", "8-bit Black", imw, imh, tnum*znum);
	xycorID=getImageID();
	for(i=0; i<tnum;i++) {
		for(j=0; j<znum;j++) {
			selectImage(originalID);
			setSlice(i*znum+j+1);
			run("Select All");
			run("Copy");			
			selectImage(xycorID);
			setSlice(i*znum+j+1);
			makeRectangle(-1*xshiftA[i], -1*yshiftA[i], imw, imh);
			run("Paste");	
		}
	}
	setBatchMode("exit and display");
}

//080318
macro "XYZ corrector Reference Particel" {
	particleID = getNumber("Which Partcle?", 1);
	stackID = getImageID();

	znum=15;
	if (((nSlices/znum) - floor(nSlices/znum)) !=0) exit("wrong stack??");
	op = "group="+znum+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	zprojID = getImageID();

	XYZcorrectbyID(stackID, "XY", particleID, znum, zprojID);
}

function XYZcorrectbyID(stackID, dimension, particleID, znum, zprojID){

	selectImage(stackID);
	//frames=nSlices;
//	if (dimension =="xz") zscale = getNumber("z scale?", 10);
	zscale = getNumber("z scale?", 10);

	selectImage(zprojID);
	imw = getWidth();
	imh = getHeight();
 	tnum = nSlices;

	newImage("xprojection", "8-bit Black", imw, znum, tnum);
	xprojID =  getImageID();
	setBatchMode(true);
	xprojectionCore(stackID, xprojID , znum);
	selectImage(xprojID);
	op = "width="+imw+" height="+zscale*znum;
	run("Size...", op);
	setBatchMode("exit and display");

	currentxA = newArray(nSlices);
	currentyA = newArray(nSlices);
	currentzA = newArray(nSlices);
	currentfA = newArray(nSlices);
	shiftxA = newArray(nSlices);
	shiftyA = newArray(nSlices);
	shiftzA = newArray(nSlices);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;
	}
	//fullpathname = File.openDialog("Select a track File");
	//openedDirectory = File.getParent(fullpathname );
	//openedFile = File.getName(fullpathname );
	//tempstr = File.openAsString(fullpathname);
	tempstr = File.openAsString(G_TrackfileFullPath);

	lineA=split(tempstr,"\n");

//	tracknum = 1;
	framecount = 0;
	trackexists = 0;
	wh = getHeight();

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if ((linecontentA.length>1) && (parseInt(linecontentA[0])==particleID)) {
				tracknum = parseInt(linecontentA[0]);
				currentslice = parseInt(linecontentA[1]);
				currentX = parseFloat(linecontentA[3]);
				currentY = parseFloat(linecontentA[2]);
				currentZ = parseFloat(linecontentA[4]);

				print(tracknum+ "-"+currentslice + ":x " + currentX + ", y " + currentY + ", z " + currentZ);
				currentfA[framecount] = currentslice;
				currentxA[framecount] = currentX;
				currentyA[framecount] = currentY;
				currentzA[framecount] = currentZ;
				shiftxA[framecount] = currentxA[framecount] - currentxA[0];
				shiftyA[framecount] = currentyA[framecount] - currentyA[0];
				shiftzA[framecount] = currentzA[framecount] - currentzA[0];
				print(tracknum+ "-"+currentslice + ":dx " + shiftxA[framecount] + ", dy " + shiftyA[framecount] + ", dz " + shiftzA[framecount]);
		 		framecount++;
		} 
//		framecount =0;
//		tracknum+=1;
	}
	selectImage(stackID);

	setBatchMode(true);
	newImage("xycorrectedZproj", "8-bit Black", imw, imh, tnum);
	zproCorjID = getImageID;	
	for(i=0; i<tnum;i++) {
		selectImage(zprojID);		
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(zproCorjID);	
		setSlice(i+1);
		makeRectangle(-1*shiftxA[i], -1*shiftyA[i], imw, imh);
		run("Paste");
	}	
	newImage("xycorrected", "8-bit Black", imw, imh, tnum*znum);
	xycorID=getImageID();
	for(i=0; i<tnum;i++) {
		for(j=0; j<znum;j++) {
			selectImage(stackID);
			setSlice(i*znum+j+1);
			run("Select All");
			run("Copy");			
			selectImage(xycorID);
			setSlice(i*znum+j+1);
			makeRectangle(-1*shiftxA[i], -1*shiftyA[i], imw, imh);
			run("Paste");	
		}
	}
	setBatchMode("exit and display");

	//----------- Zshifting
	zmax = K_retrunArrayMax(shiftzA);
	zmin = K_retrunArrayMin(shiftzA);
	range = zmax -zmin;
	range = (floor(range/zscale )+1) * zscale ;			//to make it scaleable with Gzscaler	
	print("zmin"+zmin+" zmax"+zmax+"range"+range);
	newImage("z-shifted", "8-bit Black", imw, znum*zscale +range, tnum);
	zcorrectedXprojID = getImageID();

	zshiftthreshold =0.5;
	shiftzroundA= newArray(shiftzA.length);
	for (i=0; i< shiftzroundA.length; i++) {
/*		tempresidue = shiftzA[i] - floor(shiftzA[i]);
		if (abs(tempresidue) > zshiftthreshold ) {	
			yshiftaroundA[i] = round(yshiftA[i]);
		} else {
			if (yshiftA[i] >=0)
				yshiftaroundA[i] = floor(yshiftA[i]);
			else
				yshiftaroundA[i] = floor(yshiftA[i])+1;
		}			
*/
		shiftzroundA[i] = round(shiftzA[i]);
	}
	zmaxstack = K_retrunArrayMax(shiftzroundA);
	zminstack = K_retrunArrayMin(shiftzroundA);
	newzslices = znum + zmaxstack - zminstack;
	print("zminstack"+zminstack +" zmaxstack"+zmaxstack +"newslices"+newzslices );

	setBatchMode(true);
	for (i=0; i<tnum; i++) {
		selectImage(xprojID);		
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(zcorrectedXprojID);	
		setSlice(i+1);
		makeRectangle(0, -1*zmin-shiftzroundA[i], imw, znum*zscale );
		run("Paste");
		print("t:" + i + "  zshift:"+shiftzA[i] + " approximated to "+ shiftzroundA[i]);
	}
	setBatchMode("exit and display");

	zexpandSwitch = 0;
	if (zexpandSwitch == 1) {
		print("New Slice Number: "+newzslices);
		newImage("z-shiftedStack", "8-bit Black", imw, imh,newzslices*tnum);
	} else {
		print("New Slice Number: "+znum);
		newImage("z-shiftedStack", "8-bit Black", imw, imh,znum*tnum);
	}
	zcorrectedStackID = getImageID();

	//condition the background
	dummyframe = 1; //frame used as default background
	setBatchMode(true);
	selectImage(stackID);
	setSlice(dummyframe);
	run("Select All");
	run("Copy");
	selectImage(zcorrectedStackID);
	for (i=0; i<nSlices; i++) {
		setSlice(i+1);
		run("Paste");			
	}
	setBatchMode("exit and display");
	
	//run("Add Noise", "stack");
	//run("Despeckle", "stack");
	setBatchMode(true);
	for (i=0; i<tnum; i++) {
		for (j=0; j<znum; j++) {
			selectImage(xycorID);
			setSlice(i*znum+j+1);
			run("Select All");
			run("Copy");
			selectImage(zcorrectedStackID);		
			//setSlice(i*newzslices+j+1+shiftzroundA[i]);
			if (zexpandSwitch == 1) {
				setSlice(i*newzslices+j+1-shiftzroundA[i]);
				run("Paste");			
			} else {
				if (((j - shiftzroundA[i]) >= 0) && ((j - shiftzroundA[i]) < znum)) {
					setSlice(i*znum+j+1-shiftzroundA[i]);
					run("Paste");			
				}
			}
		}
		if (abs(shiftzroundA[i])>0) {
			print("timepoint:"+i+" shifted"+shiftzroundA[i]);
		}
	}
	setBatchMode("exit and display");



}

function K_retrunArrayMax(aA) {
	aA_max=-500000; //LIB
	for (k=0;k<aA.length;k++) if (aA_max<aA[k]) aA_max=aA[k];
	return aA_max;
 }

function K_retrunArrayMin(aA) {
	aA_min=500000; //LIB
	for (k=0;k<aA.length;k++) if (aA_min>aA[k]) aA_min=aA[k];
	return aA_min;
 }

//input = x and y position
macro "Particle ID finder [f5]"{
	particleX= getNumber("x?", 0);
	particleY= getNumber("Y?", 0);
	particlefinder(particleX, particleY);
}

function particlefinder(particleX, particleY){
/*	fullpathname = File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	G_TrackfileFullPath = fullpathname;
*/	tempstr = File.openAsString(G_TrackfileFullPath);

	lineA=split(tempstr,"\n");

	framecount = 0;
	trackexists = 0;
	currenttrack = -1;
	mindx = 10000;
	mindy = 10000;
	
	closestX = 0;
	closestY = 0;
	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			tracknum = linecontentA[0];
			if (tracknum != currenttrack ) {
				currentslice = linecontentA[1];
				currentX = linecontentA[3];
				currentY = linecontentA[2];
				currentZ = linecontentA[4];

				if ((abs(currentX - particleX) + abs(currentY - particleY)) < (mindx+mindy)) {
					mindx = abs(currentX - particleX);
					mindy = abs(currentY - particleY);
					closestX = currentX;
					closestY = currentY;
					closestparticle = tracknum;
				}	
				//print(tracknum+ "-"+currentslice + ":x " + currentX + ", y " + currentY + ", z " + currentZ);
				currenttrack = tracknum;
			}
		} 
	}
	print("("+particleX + "," +particleY+")");
	print("-->Closest Track: " + closestparticle + " x:"+closestX + " y:"+closestY);


}


macro "-"{}

var G_Sdir="D:\\_Kota\\CMCI\\course_macro\\"
var G_Ddir="D:\\_Kota\\CMCI\\course_macro\\"

macro "Tiff Series Saving For Imaris 6.0 Z-T" {
	ImarisSaver(0);
}

macro "Tiff Series Saving For Imaris 6.0 T-Z" {
	ImarisSaver(1);
}

function ImarisSaver(order) {
	totalframes = nSlices;
	if (nSlices==0) exit("this function is for stacks");
	zslices = getNumber("How many zslices?", 15);
	if (totalframes%zslices !=0) exit("wrong z slice number");
	timepoints = totalframes/zslices;
	prefix = getString("file prefix?", "seq");
	stackID = getImageID();
	imw=getWidth();
	imh=getHeight();
	G_Ddir = getDirectory("Choose Destination Directory");
	print(G_Ddir);
	slicecounter=1;
	setBatchMode(true);
	for (j = 0; j<timepoints; j++) {
		for (i = 0; i<zslices; i++) {
			selectImage(stackID);
			setSlice(slicecounter);
			run("Select All");
			run("Copy");	

			newImage("temp", "8-bit Black", imw, imh, 1);
			run("Paste");
			tp =  leftPad(i, 3);
			zp =  leftPad(j, 3);
			if (order ==0)	fullpath = G_Ddir + prefix + "_"+zp+"_"+tp+".tif";
			if (order ==1)	fullpath = G_Ddir + prefix + "_"+tp+"_"+zp+".tif";
			saveAs("tiff", fullpath);
			close();
			slicecounter++;
		}
	}
	setBatchMode("exit and display");
}

// number padding
function leftPad(n, width) {
	s =""+n;
	while (lengthOf(s)<width)
		s = "0"+s;
	return s;
}

//080311 converts semi-colon delimimted files to tab-delimited. 
macro "Track Converter Imaris semicolon to tab delimited"{
 	print("\\Clear");
	fullpathname = File.openDialog("Select a Imaris CSV File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	//tempstr = File.openAsString("");
	linesA=split(tempstr,"\n");
	trajectoryCount=1;
	//f1 = File.open("converted.txt");
	for (i=0; i < linesA.length; i++) {
		outstr ="";
		paramA=split(linesA[i], ";");
		for (j=0; j<paramA.length;j++) {
			outstr = outstr+paramA[j]+"\t";
		}
		print(outstr);
	}	
	selectWindow("Log");
	saveAs("text");
	print(fullpathname);
}
