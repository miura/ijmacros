// Yeast chromosome dynamics, April 2010-
//Kota MIura

var Gtimepoints = 5;
var Gzslices = 8;
var GcircularityMin = 0.5;
var GcircularityMax = 1.0;
var Groisize = 1.5; //factor to be multipied to estimated diameter of yeast. 
var Gcellcounter =0;

var G_RID;	// ch0 imageID.
var G_GID; 	// ch1 imageID. 
var Rtitle="ig0";
var Gtitle="ig1";

var G_Rsub1ID;	// ch0 imageID, sub stack single cell time series.
var G_Gsub1ID; 	// ch1 imageID, sub stack single cell time series. 

var G_Rsub2ID;	// ch0 imageID, sub stack single cell single time point.
var G_Gsub2ID; 	// ch1 imageID, sub stack single cell single time time point. 


var pos3DA = newArray(3); //x, y, z
var dotsposA = newArray(8); //3 for ch0, 3 for ch1 {x1, y1, z1, x2, y2, z2, ch0dotnumber, ch1dotnumber}	

macro "Bleach Corection 3D-t by ratio"{
	run("Duplicate...", "title=bleach_corrected duplicate");
	getDimensions(width, height, channels, slices, frames);
	if (frames == 1) {
		uslices = getNumber("how many z slices/timepoint?", 1);
		if ((slices%uslices) !=0) exit("that slice number dows not match with the current stack");
		frames = slices / uslices;
	}
	tIntA = newArray(frames);
	setBatchMode(true);
	for(i=0; i<frames; i++){
		startf = (i*slices)+1;
		endf = (i+1)*slices;
		op ="start="+startf+" stop="+endf+" projection=[Sum Slices]";
		run("Z Project...", op);
		//print(op);
		getRawStatistics(nPixels, mean);
		if (i==0) tIntA[i] = mean;
		else tIntA[i] = mean/tIntA[0];
		close();
	}
	setBatchMode("exit and display");
	tIntA[0] =1;
	for(i=0; i<frames; i++){
		for(j=0; j<slices; j++){
			curframe = i*slices + j+1;
			setSlice(curframe);
			//print("frame"+curframe + " factor" + tIntA[i]);
			op = "value="+tIntA[i]+" slice";
			run("Divide...", op);
		}
		print("time point:"+i+1 + "  factor" + tIntA[i]);
	}	
}



//******************


macro "FFT band pass"{
	FFTbandpass(getImageID());
}
function FFTbandpass(imID){
		selectImage(imID);
		FFTargument = "filter_large="+10
				+" filter_small="+2
				+" suppress=None"
				+" tolerance="+5
				+" process";
		print(FFTargument);
		run( "Bandpass Filter...", FFTargument); 
}


//test function for FFT + loading trained data and segment
function DoTrainedSegmentation(){
	//call("EMBLBory.DotSegmentBy_Trained.setDatapath");
	call("EMBLBory.DotSegmentBy_Trained.setDatapath", "C:\\HDD\\People\\Bory\\100423\\data100423.arff");
	//call("EMBLBory.DotSegmentBy_Trained.ProcessImageAt", "C:\\HDD\\People\\Bory\\100423\\tt.tif");
	call("EMBLBory.DotSegmentBy_Trained.ProcessImageAt", "C:\\HDD\\People\\Bory\\testChromosome\\3con170210_6_R3D.dv - C=0.tif");
}

//****************

macro "-"{}

//window chooser
macro "Choose Images  for each channel  [f1]" {
	requires("1.43d");	//090526 for stack function
	twoImageChoice();
	selectWindow(Gtitle);	//ch1
	G_GID = getImageID();
	selectWindow(Rtitle);	//ch0
	G_RID = getImageID();
	resetThreshold();	
}

macro "... FFT assigned channels"{
	FFTbandpass(G_RID);
	FFTbandpass(G_GID);
}

macro "... Reset cell counter"{
	Gcellcounter =0;
}

// windows should be assigned, FFT shoud be done ROI for a cell must be set already
macro "segmentation & measure single cell time series" {
	selectImage(G_RID);
	if (selectionType() != 0) exit("Need a Rectangular Selection in Channel 0");
	getBoundingRect(x, y, width, height);

	if(is("hyperstack")) run("Hyperstack to Stack");
	Stack.getDimensions(stackw, stackh, channels, slices, frames);
	run("Select None");	
	makeRectangle(x, y, width, height);
	run("Duplicate...", "title=ch0cell_timeseries duplicate");
	G_Rsub1ID = getImageID();
	
	selectImage(G_GID);
	if(is("hyperstack")) run("Hyperstack to Stack");
	run("Select None");	
	makeRectangle(x, y, width, height);
	run("Duplicate...", "title=ch1cell_timeseries duplicate");
	G_Gsub1ID = getImageID();
	
	newImage("ch0Binstack.tif", "8-bit Black", width, height, nSlices);
	ch0binstackID = getImageID();
	newImage("ch1Binstack.tif", "8-bit Black", width, height, nSlices);
	ch1binstackID = getImageID();

	Gcellcounter++;

	for(i=0; i<frames; i++) {
	//for(i=0; i<1; i++) { //test
		startframe = i * slices + 1;
		endframe = (i+1) * slices;
		op = "slices="+startframe+"-"+endframe;

		selectImage(G_Rsub1ID);
		run("Substack Maker", op);
		G_Rsub2ID = getImageID();

		selectImage(G_Gsub1ID);
		run("Substack Maker", op);
		G_Gsub2ID = getImageID();

		distance = MeasureDotDotDistCore(G_Rsub2ID, G_Gsub2ID); //single time point
		//for out put f detected positions
		selectWindow("ch0classified");
		for(j=0; j<nSlices; j++) {
			setSlice(j+1);
			run("Select All");run("Copy");
			selectImage(ch0binstackID);
			setSlice((i*slices)+j+1);
			run("Paste");
			selectWindow("ch0classified");
		}
		selectWindow("ch0classified"); close();

		selectWindow("ch1classified");
		for(j=0; j<nSlices; j++) {
			setSlice(j+1);
			run("Select All");run("Copy");
			selectImage(ch1binstackID);
			setSlice((i*slices)+j+1);
			run("Paste");
			selectWindow("ch1classified");
		}
		selectWindow("ch1classified"); close();

		datapoint = nResults;
		setResult("cellID", datapoint, Gcellcounter );
		setResult("time", datapoint, i+1);
		setResult("distance",datapoint, distance);
		setResult("d1x", datapoint, dotsposA[0]);
		setResult("d1y", datapoint, dotsposA[1]);
		setResult("d1z", datapoint, dotsposA[2]);
		setResult("ch0dotNumber", datapoint, dotsposA[6]);
		setResult("d2x", datapoint, dotsposA[3]);
		setResult("d2y", datapoint, dotsposA[4]);
		setResult("d2z", datapoint, dotsposA[5]);
		setResult("ch1dotNumber", datapoint, dotsposA[7]);

		updateResults();
		selectImage(G_Rsub2ID); close();
		selectImage(G_Gsub2ID); close();
	}
	setBatchMode(true);

	selectImage(G_Rsub1ID);	
	run("Grouped ZProjector", "group="+slices+" projection=[Max Intensity]");
	run("8-bit");
	ch0cellprojID = getTitle();

	selectImage(G_Gsub1ID);	
	run("Grouped ZProjector", "group="+slices+" projection=[Max Intensity]");
	run("8-bit");
	ch1cellprojID = getTitle();

	selectImage(ch0binstackID);
	run("Grouped ZProjector", "group="+slices+" projection=[Max Intensity]");
	ch0binstackProjID = getTitle();

	selectImage(ch1binstackID);
	run("Grouped ZProjector", "group="+slices+" projection=[Max Intensity]");
	ch1binstackProjID = getTitle();

	op = "red=["+ch0binstackProjID+"] green=["+ch1binstackProjID +"] blue=*None* gray=["+ch0cellprojID +"] create keep";
	run("Merge Channels...", op);

	op = "red=["+ch0binstackProjID+"] green=["+ch1binstackProjID +"] blue=*None* gray=["+ch1cellprojID +"] create keep";
	run("Merge Channels...", op);

	selectWindow(ch0cellprojID ); close();
	selectWindow(ch1cellprojID ); close();
	selectWindow(ch0binstackProjID); close();
	selectWindow(ch1binstackProjID); close();

	selectImage(ch0binstackID); close();
	selectImage(ch1binstackID); close();

	setBatchMode("exit and display");
	
}


//window should be set already
macro "test segmentation & Measure single time point z-stacks"{
	MeasureDotDotDistCore(G_RID, G_GID);
}

function MeasureDotDotDistCore(ch0id, ch1id){
	selectImage(ch0id);

	getVoxelSize(vwidth, vheight, vdepth, vunit);
	zfactor = vdepth/vwidth;

	call("EMBLBory.DotSegmentBy_Trained.setDatapath", "C:\\HDD\\People\\Bory\\testChromosome\\ch0f1dataRnd2_05.arff");
	call("EMBLBory.DotSegmentBy_Trained.ProcessTopImage");
	rename("ch0classified");
	ch0binID = getImageID();
	//getRawStatistics(nPixels, mean, min, max);

	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	
	if (max>0) {
		ch0dotnum = GetDotCoordinates();
		for(i=0; i<pos3DA.length; i++) dotsposA[i] = pos3DA[i];
	} else {
		print("===== max int was "+max+": no measurment will be made ====");
		for(i=0; i<pos3DA.length; i++) dotsposA[i] = -1;
		ch0dotnum = 0; 		
	}
	dotsposA[6] = ch0dotnum;
	
	selectImage(ch1id);
	call("EMBLBory.DotSegmentBy_Trained.setDatapath", "C:\\HDD\\People\\Bory\\testChromosome\\ch1f1data02.arff");
	call("EMBLBory.DotSegmentBy_Trained.ProcessTopImage");
	rename("ch1classified");
	ch1binID = getImageID();
	//getRawStatistics(nPixels, mean, min, max);

	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	if (max>0) {
		ch1dotnum = GetDotCoordinates();	//this will fill in pos3DA, xyz coordinates of the dot. 	
		for(i=0; i<pos3DA.length; i++) dotsposA[i+3] = pos3DA[i];
	} else {
		print("===== max int was "+max+": no measurment will be made ====");
		for(i=0; i<pos3DA.length; i++)	dotsposA[i+3] =-1;
		ch1dotnum = 0;
	}
	dotsposA[7] = ch1dotnum;


		//sumsq =0;
		//for(i=0; i<pos3DA.length; i++) sumsq+= pow(dotsposA[i]-dotsposA[i+3],2);
		//dist = sqrt(sumsq);
	if ((dotsposA[0] == -1) || (dotsposA[3] == -1) ) {	//one or either of them not measured. 
		dist = -1;
	} else {
		dist = ReturnDistZfactored(dotsposA[0], dotsposA[1], dotsposA[2], dotsposA[3], dotsposA[4], dotsposA[5], zfactor);
	}
	print("Distance:="+ dist +" "+ vunit);

	//maybe show merged? (for merging, bin stack scales should be set accordingly)
	//selectImage(ch0binID); close();
	//selectImage(ch1binID); close();
	return dist;
}

/*
macro "test dist"{
	print(ReturnDistZfactored(1, 3, 5, 10, 8, 2, 3.5));
}
*/
//distance in xy pixel scale
function ReturnDistZfactored(x1, y1, z1, x2, y2, z2, zfactor){
	distsq = pow(x1-x2, 2) + pow(y1-y2, 2) + pow(z1-z2, 2)* zfactor* zfactor;
	dist = sqrt(distsq);
	return dist;
}

// === dot position measurements. ===

//works on two binary image stacks. 
macro "test measuring two points"{
	//print(getResult("Volume", 0));
	selectWindow("test");
	GetDotCoordinates();
	for(i=0; i<pos3DA.length; i++){
		print(pos3DA[i]+"\n");
		dotsposA[i] = pos3DA[i];
	}
	selectWindow("test2");
	GetDotCoordinates();
	for(i=0; i<pos3DA.length; i++)
		dotsposA[i+3] = pos3DA[i];
	sumsq = 0;
	for(i=0; i<pos3DA.length; i++) sumsq+= pow(dotsposA[i]-dotsposA[i+3],2);
	dist = sqrt(sumsq);
	print("Distance:="+ dist);
}

//assumes there is only one dot
// should be separated with plugin calling and 3D object study. 
// should be added with 
//	(1) more eparameters, shape factor and total intensity/dot, size 
//	(2) results should be with two dots always. 
function GetDotCoordinates(){
	wintitle = getTitle();
	//following option is specific to Fiji
	run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
	//below is for Fiji pluign
	run("3D Objects Counter", "threshold=128 slice=1 min.=1 max.=480000 statistics");
	//below is for ImageJ plugin
	//run("Object Counter3D", "threshold=128 slice=1 min=10 max=480000 new_results dot=3 font=12");
	//resultwin = "Results from " + wintitle; //ImageJ
	resultwin = "Statistics for " + wintitle; //Fiji
	selectWindow(resultwin);
	//print(getInfo("window.contents"));
	tabletext = getInfo("window.contents");
	tableA = split(tabletext, "\n");
	print("detected dot number:"+tableA.length-1);
	//check how many dots were detected. it should be 1, otherwise take the largest. 
	selectedline = 1; //default, only one dot detected.
	if (tableA.length > 2) {
		print("More than two dots detected in "+wintitle);
		volumeA = newArray(tableA.length);
		for (i=1; i<tableA.length; i++) {
			templineA = split(tableA[i], "\t");
			volumeA[i] = templineA[1];
		}
		volume =0; 
		index = 0;
		for (i=1; i<volumeA.length; i++){
			if (volumeA[i] > volume) {
				volume = volumeA[i];
				index = i;
			}
		}
		selectedline = index; 
		print("   ... Index selected:"+selectedline);
	}
	if (tableA.length == 1) {	//when no dot detectd, fill -1 for return values
		pos3DA[0] = -1; //x
		pos3DA[1] = -1; //y
		pos3DA[2] = -1; //z

	} else {
		lineA = split(tableA[selectedline], "\t");
			//pos3DA[0] = lineA[4]; //x  these are cases when using ImageJ
			//pos3DA[1] = lineA[5]; //y
			//pos3DA[2] = lineA[6]; //z

		pos3DA[0] = lineA[11]; //x these are cases when using Fiji 
		pos3DA[1] = lineA[12]; //y
		pos3DA[2] = lineA[13]; //z

	}
	return (tableA.length-1); //number of dots detected.
}


/*	3D object counting part

	if (GsingularFISHsignal ==1) {	//090728
		print("      Object3D counter: Minimum voxels="+GminimumFISHvoxelSize);
		minimumvoxels =  KreturnOptimizedMinimumVoxleCutoff(getImageID()); //090729
		if (minimumvoxels != GminimumFISHvoxelSize) print("      Minimum Voxel Cutoff changed to --> "+minimumvoxels + " (default = "+GminimumFISHvoxelSize+")"); //090729

		//op = "threshold=128 slice="+nSlices+" min="+GminimumFISHvoxelSize+" max=4000 geometrical dot=1 font=12"; //090728 somehow this causes extra signals
		//op = "threshold=128 slice="+nSlices+" min="+GminimumFISHvoxelSize+" max=4000 new_results geometrical dot=1 font=12"; //090728
		op = "threshold=128 slice="+nSlices+" min="+minimumvoxels +" max=4000 new_results geometrical dot=1 font=12"; //090729
		run("Object Counter3D", op); //090728 for getting single point, require object counter 3D
		singularsigID = getImageID();	//090728	use sigID
		run("Multiply...", "value=255 stack");	//090728
		run("8-bit");	//090728
		FISHvoxelnumber = ReturnStackHistogram255thValue();
		run("Divide...", "stack value=255"); //090728b
		run("32-bit");	//debug 090420
		rename("SingularSignal");	//090728
		imageCalculator("Multiply create 32-bit stack", EDTnucID , singularsigID );
	}

*/



//======================================================================================

macro "-"{}

// will be used for automatic detection of ROIs. 
function DoZTprojection(){
	//projection in Z
	opt = Gzslices;
	run("Grouped ZProjector", "group="+opt+" projection=[Max Intensity]");
	//projection in T
	opt = Gtimepoints;	
	run("Z Project...", "start=1 stop="+opt+" projection=[Max Intensity]");
}


//090520
macro "(original)... auto record ROI positions" {
	requires("1.43d");
	//setBatchMode(true);
	ministackpath=getDirectory("Choose a Directory toSave Mini-stacks");
	AutoROIdetector(ministackpath, 1);
	print("========= FINISHED AUTO-DETECTION");	
	//ministackAssemblerCore(ministackpath, "nosave", 0);	//090812
}

//require a 3D-t stack at the top
//resuslts are ROI coordinates and size of selected cells. 
macro "auto ROI test"{
	G_GID = getImageID();
	AutoROIdetector(0);
}

//090908
// for Kroirecords(), windows must be assigned either manually or automatically already. 
// refreshSwitch added, to refresh the nucID counting or not. =1 refreshes, =0 does not refresh
//function AutoROIdetector(ministackpath, refreshSwitch){
function AutoROIdetector(refreshSwitch){
	selectImage(G_GID);
	run("Select None");	
	op = "title=[NucFinder] duplicate range=1-"+nSlices;
	getDimensions(dapiw, dapih, dapich, dapislices, dapiframes);//090525
	run("Duplicate...", op);
	tempGaussID = getImageID();	run("Out");run("Out");
	//run("Gaussian Blur...", "sigma=4 stack");//out 090928, to speed up
		//op = "start=1 stop="+nSlices+" projection=[Max Intensity]";
		//run("Z Project...", op);
	DoZTprojection();
	projectionID = getImageID();run("Out");run("Out");
	run("Gaussian Blur...", "sigma=4");//090928 
	selectImage(tempGaussID); close();
	//selectImage(projectionID);
		//run("MultiThresholder", "Mixture Modeling");	//---> this might be better with the new strategy! //does not work in FIJI
		//KotasSegmentationEval2para3D(projectionID, 37, 1);
	setAutoThreshold("MaxEntropy dark");
	run("Convert to Mask");
	run("Invert");
	setAutoThreshold();	//with binary image, for particle anaysis
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	//setBatchMode("exit and display");

	run("Set Measurements...", "area mean standard centroid perimeter shape limit display redirect=None decimal=5");
		//maybe size should be adjusted
	analyzeOP = "size=100-100000 circularity="+GcircularityMin+"-"+GcircularityMax+" show=Nothing display exclude clear include";
	run("Analyze Particles...", analyzeOP);
	selectImage(projectionID);
	roixA = newArray(nResults);
	roiyA = newArray(nResults);
	roiwidthA = newArray(nResults);
	roiCircA = newArray(nResults);
	run("Colors...", "foreground=white background=black selection=yellow");
		//setFont("SansSerif", 16, "antialiased");	//090907
	resetThreshold(); 
	for(i=0; i<nResults; i++){
		currentArea = getResult("Area", i);
		currentX =  getResult("X", i);
		currentY =  getResult("Y", i);
		radiusestimate = sqrt(currentArea/3.1415)*Groisize;
		left = currentX - radiusestimate;
		top = currentY - radiusestimate;
		width = radiusestimate*2;
			if (left<0) left=0;	//090525
			if (top<0) top=0;	//090525
			if (left>(dapiw-width)) left=(dapiw-width-1);	//090525
			if (top>(dapih-width)) top=(dapih-width-1);	//090525
		makeRectangle(left, top, width, width);
		run("Draw");
		roixA[i] = left ;
		roiyA[i] = top;
		roiwidthA[i] = width;
		roiCircA[i] = getResult("Circ.", i);
  		drawString("cell"+(i+1), left+width/2, top + width + 20);	//090907
		print("ROIid"+i+":"+left+" , "+ top+ " w="+width);
		ResTLabelA[Gmeascount] = i;
		ResTnucIDA[Gmeascount] = Gmeascount;
		ResTroiXA[Gmeascount]=roixA[i];
		ResTroiYA[Gmeascount]=roiyA[i];
		ResTroiWidthA[Gmeascount]=roiwidthA[i];
		ResTroiHeightA[Gmeascount]=roiwidthA[i];
		ResTNucCircA[Gmeascount] = roiCircA[i];
		Gmeascount++; 
	}
	//print(Gmeascount);
	run("Clear Results"); 
	updateResults(); 

	if (refreshSwitch) {
		Gmeascount = 0;	//090908 should change this probably
		RefreshResultsTableArrays();
	}
	for(i=0; i<roixA.length; i++){
		print("========= cell" + (i+1));	
		selectImage(G_GID);
		makeRectangle(roixA[i], roiyA[i], roiwidthA[i], roiwidthA[i]);
		//Kroirecords(ministackpath, 1);	//batch mode
	}
	DisplayResultsTableArrays();//batch mode

	return projectionID;	//090908
}

// arrays for Results table //090908  Store all info in these arrays, load, refresh, displaytoResults
var ResRowMax =3000;
var ResTLabelA=newArray(ResRowMax );
var ResTnucIDA=newArray(ResRowMax );
var ResTroiXA=newArray(ResRowMax );
var ResTroiYA=newArray(ResRowMax );
var ResTroiWidthA=newArray(ResRowMax );
var ResTroiHeightA=newArray(ResRowMax );

var ResTmaxradiusA=newArray(ResRowMax );
var ResTCh1DotNumberA=newArray(ResRowMax );
var ResTCh2DotNumberA=newArray(ResRowMax );

var ResTNucCircA=newArray(ResRowMax );	//091005

var Gmeascount = 0;

function RefreshResultsTableArrays(){
	for(i=0; i<ResTLabelA.length; i++){
		ResTLabelA[i]=0;
		ResTnucIDA[i]=0;
		ResTroiXA[i]=0;
		ResTroiYA[i]=0;
		ResTroiWidthA[i]=0;
		ResTroiHeightA[i]=0;

		ResTmaxradiusA[i]=0;
		ResTCh1DotNumberA[i]=0;
		ResTCh2DotNumberA[i]=0;
		ResTNucCircA[i]=0;
	}
}

//091005added circularity
function DisplayResultsTableArrays(){
	run("Clear Results"); //091014
	for(i=0; i<Gmeascount; i++){	
		setResult("Label", i, ResTLabelA[i]);
		setResult("nucID", i,  ResTnucIDA[i]);
		setResult("roiX", i, ResTroiXA[i]);
		setResult("roiY", i, ResTroiYA[i]);
		setResult("roiWidth", i, ResTroiWidthA[i]);
		setResult("roiHeight", i, ResTroiHeightA[i]);

		setResult("yeastmaxRadius", i, ResTmaxradiusA[i]);
		setResult("CH1DotNumber", i, ResTCh1DotNumberA[i]);
		setResult("CH2DotNumber", i, ResTCh2DotNumberA[i]);
		setResult("NucCircularity", i, ResTNucCircA[i]);					
	}
	updateResults();
}

//091005added circularity
function LoadResultsTableArraysfromDisplayed(){
	RefreshResultsTableArrays();
	for(i=0; i<nResults; i++){	
		ResTLabelA[i] = getResultLabel(i);
		ResTnucIDA[i] = getResult("nucID", i);
		ResTroiXA[i] = getResult("roiX", i);
		ResTroiYA[i] = getResult("roiY", i);
		ResTroiWidthA[i] = getResult("roiWidth", i);
		ResTroiHeightA[i] = getResult("roiHeight", i);

		ResTmaxradiusA[i] = getResult("yeastmaxRadius", i);
		ResTCh1DotNumberA[i] = getResult("CH1DotNumber", i);
		ResTCh2DotNumberA[i] = getResult("CH2DotNumber", i);
		ResTNucCircA[i] = getResult("NucCircularity", i);	
	}
}



//============= funcitons reused from 3DdistancemapV4

//Kota: choosing two images among currently opened windows
function twoImageChoice() {
	//imgnum=Wincount();
	imgnum=nImages();//Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("select two images");
	//Dialog.addNumber("number1:", 0);
 	//Dialog.addNumber("number2:", 0);
	Dialog.addChoice("Ch 0", wintitleA);
	Dialog.addChoice("Ch 1", wintitleA);
 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 = Dialog.getNumber();;
 	Rtitle = Dialog.getChoice(); //0
	Gtitle = Dialog.getChoice(); //1
	print("ch0" + Rtitle);
	print("ch1:"+Gtitle);
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

