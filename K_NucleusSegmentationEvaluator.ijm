//K_NucleusSegmentationEvaluator.ijm
//Kota Miura (miura at embl dot de)
// Jan. 2009 (originally "Rotation.ijm")
//
//Compare Segmentation strategies for FISH position determination within nucleus. 
// related doc.  Ritsuko's paper081201.rtf
//090421, 090421 scale setting in function RIMstudyCoreSYS

//work flow
// 1. assign windows. [f3]
// 2. measure the deviation between Lamin edge (peak position) and DAPI edge (various with segmentation strategy & degree of saturation)

var Gtitle="ig1";	
var Rtitle="ig2";

var G_GID=0;	
var G_RID=0;	

var GThNucL;
var GThNucH;

var GXYscale = 1;

//090421
function XYscaleSetter() {
	getVoxelSize(stackw, stackh, Gzscale_um, stackunit);
	if(Gzscale_um==0) {
		print("no info on voxel depth associated with the image");
		exit("failed getting scale info: check the log window");
	} else {
		GXYscale = stackw;
		print("XYscale: "+GXYscale+" [um]");
	}
}


//var Gmeascount2 = 0;

var Gsavepath ="C:\\kota\\ritsuko\\090216handeddata\\090319smallregion\\";
//var Gsavepath ="D:\\People\\Ritsuko\\090317_deviationanalysis\\090320LargeParameterSpace\\";

macro "set data save path [F8]"{
	Gsavepath = getDirectory("Choose a Directory");
}

//080908
// search for the highest instensity slice, and get the threshold automatically
macro "Set Threshold for the Nucleus Auto (used in 2008)" {
	 getAutoThresholdNucleus();
	
}

//080908
// preivious one. Threshold level is determined from the whole frame. 
function getAutoThresholdNucleus() {
	run("Select None");		//081212
	G_GID = getImageID();
	setBatchMode(true);
	run("Duplicate...", "title=[temp_thrsholdFinder] duplicate");		//081212
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
	//setAutoThreshold();
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
	setThreshold(lower, upper);
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


//***************************** begin assign windows *********************** copied from K_3DdistancemapV2.ijm
//window ID assign manually. 
//when choosing, choos lamin as "signal" and dapi as "nucleus"
macro "Assign Windows  [f3]" {
	twoImageChoice();
	selectWindow(Gtitle);	//DAPI
	G_GID = getImageID();
	selectWindow(Rtitle);	//FISH
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

//***************************** end assign windows ***********************


macro "-"{}

//test phase 2

macro "dev. detect Lamin rim"{
	degincrements =10; 
	rimposxA = newArray(360/degincrements);
	rimposyA = newArray(360/degincrements);
	centx =100;
	centy = 100;

	SetToHighestIntensitySlice();	//optional
	RimDetector(rimposxA, rimposyA, centx, centy, degincrements);

	run("Select None");
	run("Duplicate...", "title=detected_rim");
	run("RGB Color");
	for(i=1; i<rimposxA.length; i++){
		setColor(255, 0, 0);
		drawLine(rimposxA[i-1], rimposyA[i-1], rimposxA[i], rimposyA[i]);
	}
}	

//090108 currently uses line-fitting peak detector but it should also be possible simply by skeletonizing.
//090115 raidus adjusted 
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

function RimDetectorBinary(rimposxA, rimposyA, centx, centy) {
	for (i=0; i<36; i++) {
		deg = 10*i;	
		setLineROIwithAngle(centx , centy , 90, deg);
		intA = getProfile();
		intA = getProfile();
		edgepos = ReturnBinaryEdigeRotate(intA);
		rad = deg/180*3.1415;
		rotx = cos(rad)*edgepos + centx;
		roty = sin(rad)*edgepos +centy;	
		rimposxA[i] = rotx;
		rimposyA[i] = roty;
	}

	
//	Plot.create("Profile", "X", "int", intcumA);
//	Plot.add("circles", intA);
//	Plot.add("line", markpeakXA, markpeakA);	
}


//test phase 1
//there should be a window with size 200 by 200 pixels.
macro "dev. set line ROI Detect edge Positin (lamin ring)"{
	deg = getNumber("angle in deg?", 10);
	setLineROIwithAngle(100, 100, 80, deg);
	intA = getProfile();
	edgepos = ReturnBinaryEdigeRotate(intA);
	markpeakXA = newArray(edgepos , edgepos );
	markpeakA = newArray(0, intA[edgepos ]);
	
	Plot.create("Profile", "X", "int", intA);
	Plot.add("line", markpeakXA, markpeakA);	
}



//test phase 1
// for determingng Lamin peak position 
macro "dev. set line ROI arb. angle"{
	deg = getNumber("angle in deg?", 10);
	setLineROIwithAngle(100, 100, 50, deg);
	intA = getProfile();
	intcumA = newArray(intA.length);
	CumulateArray(intA, intcumA);
	maxpos = ReturnSteepestPointCum(intcumA, 7);
	markpeakXA = newArray(maxpos, maxpos);
	markpeakA = newArray(0, intcumA[maxpos]);
	
	Plot.create("Profile", "X", "int", intcumA);
	Plot.add("circles", intA);
	Plot.add("line", markpeakXA, markpeakA);	

}

//set ROI and getPeakPosition
function setLineROIwithAngle(centx, centy, radius, deg){
	rad = deg/180*3.1415;
	rotx = cos(rad)*radius + centx;
	roty = sin(rad)*radius+centy;
		// here might need routine to avoid outside the image frame
	makeLine(centx, centy, rotx, roty);	// could be opposite, depending on the result of slope detection protocol
}

//test phase 0
macro "dev. draw a circle"{
	testRotation(100, 100, 50, 10);
}

function testRotation(centx, centy, radius, increment){
	for (deg=0; deg<360; deg+=increment){
		rad = deg/180*3.1415;
		rotx = cos(rad)*radius + centx;
		roty = sin(rad)*radius+centy;
		setPixel(rotx, roty, 255);
	}
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

// peak detection using linear fitting. there should only be one single peak in the array
function ReturnSteepestPointCum(cumA, boxsize) {
	xA = newArray(cumA.length);
	slopeA = newArray(cumA.length-boxsize);
	boxYA = newArray(boxsize);
	boxXA = newArray(boxsize);

	maxslope = 0;
	maxpos =0; 
	for(i=0; i<slopeA.length; i++) {
		for (j=0; j<boxsize; j++) {
			boxXA[j] = i+j; 
			boxYA[j] = cumA[i+j]; 
		}
		Fit.doFit("Straight Line", boxXA, boxYA);
		currentslope = Fit.p(1);
		if (abs(currentslope)>maxslope){
			maxslope = abs(currentslope);
			maxpos = i + round(boxsize/2);
		}
	}
	//print("Steepest x="+maxpos+" slope="+maxslope);
	return maxpos; 
}

function ReturnBinaryEdigeRotate(profileA) {
	edgepoint =0; 
	if (profileA[0] !=255) exit("not measuring binary, or maybe nuclear shape is not circular disc");
	i =0;
	while(profileA[i]==255) i++;
	edgepoint = i;
	print("edge x="+edgepoint);
	return edgepoint; 
}

macro "-"{}

var Gmeascount2 =0;

macro "... Clear Rsults Table & Reset Counter to 0"{
	Gmeascount2 =0;
	 run("Clear Results");
}

macro "... Delete Results of specific NucID (no restting of nuc counter)"{
	if (nResults>0) {
		deleteID = getNumber("Which Row?", 1);
		DeleteSpecificResults(deleteID);
		//Gmeascount2 -=1;
		print("xxxxxxx deleted the result of nucID"+deleteID+ " xxxxxxx");
		print("xxxxxxx current nuc No.(Gmeascount2)->"+Gmeascount2+ " xxxxxxx");
	} else exit("no result in results table");	
}

macro "... Load current nucIDfrom Results win"{
	Gmeascount2 = getResult("nucID", nResults-1);
	print("--> current nucID set to"+Gmeascount2);
}

function DeleteSpecificResults(deleteID){
	labelarrayA = newArray("nucID", "roiX", "roiY", "roiWidth", "roiHeight", 
		"Rsq", "RsqMean", "Sigma", "SigmaMean", 
			"Rsq2", "RsqMean2", "Sigma2", "SigmaMean2" );

	oldN = nResults;
	newN = nResults-1;
	tempA = newArray(newN);
	counter =0;
	for(j=0; j<oldN; j++){
		tempstr=getResultLabel(j)+"\t";
		if(j!=deleteID-1) {
			for(i=0; i<labelarrayA.length; i++) tempstr =tempstr+ getResult(labelarrayA[i], j)+"\t";
			tempA[counter] = tempstr;
			counter++;
			//print(tempstr);
		}
	}
	 run("Clear Results");

	for(j=0; j<newN; j++){
		dataA = split(tempA[j]);
		setResult("Label",j,dataA[0]);
		for(i=0; i<labelarrayA.length; i++) setResult(labelarrayA[i], j, dataA[i+1]);
	}
	updateResults();
	
}

//090108
// this macro requires two windows open and assigned, one for lamin and one for dapi. 
// requires multithresholder plugin. 
macro "Nucleus RIM detection Study 2D compare with lamine edge [F1]" {
	RIMstudyCore();
}

macro "... do same using ROI info in Results window"{
	if (nResults==0) exit("nothing in results window");
	iteration = nResults;
	Gmeascount2 =0;
	for (i=0; i<iteration; i++){
		fileinfostr = getResultLabel(i);
		dapititle = returnDapiTitle(fileinfostr);
		selectWindow(dapititle);
		G_GID = getImageID();
		lamintitle = returnLaminTitle(fileinfostr);
		selectWindow(lamintitle );
		G_RID = getImageID();

		selectImage(G_GID);
		makeRectangle(getResult("roiX", i), getResult("roiY", i),getResult("roiWidth", i),getResult("roiHeight", i));
		RIMstudyCore();
	}n
	updateResults();
}

// forsingle parameter pare results. 090311
//gausssigma1, gausssigma2
// 090421 this macro should be used for estimating lamin diameter.  
macro "... do same using ROI info in Results window NEW print results in log window  [F5]"{
	gausssigma1=-1;	//old strategy
	gausssigma2=-1;
/*
	gausssigma1=37;	//new strategy
	gausssigma2=1;
*/
	Gparanum1 =1;
	Gparanum2 = 1;
	Gparastep1 =1; 
	Gparastep2 =1;
 	Gparastart1 = gausssigma1;

	if (nResults==0) exit("nothing in results window");
	iteration = nResults;
	nucnum = nResults;
	//rsqA, rsqmeanA, sigmaA, sigmameanA, rsq2A, rsqmean2A, sigma2A, sigmamean2A     
	rsqA = newArray(nucnum);
	rsqmeanA = newArray(nucnum);	
	sigmaA = newArray(nucnum);	
	sigmameanA = newArray(nucnum);	
	rsq2A = newArray(nucnum);
	rsqmean2A = newArray(nucnum);	
	sigma2A = newArray(nucnum);	
	sigmamean2A = newArray(nucnum);	
	nucsegfailA = newArray(nucnum);//090317
	Gmeascount2 =0;
	for (i=0; i<iteration; i++){
		fileinfostr = getResultLabel(i);
		dapititle = returnDapiTitle(fileinfostr);
		selectWindow(dapititle);
		G_GID = getImageID();

		lamintitle = returnLaminTitle(fileinfostr);
		selectWindow(lamintitle );
		G_RID = getImageID();

		selectImage(G_GID);
		makeRectangle(getResult("roiX", i), getResult("roiY", i),getResult("roiWidth", i),getResult("roiHeight", i));
		RIMstudyCoreSYS(gausssigma1, gausssigma2, i, nucnum, rsqA, rsqmeanA, sigmaA, sigmameanA, rsq2A, rsqmean2A, sigma2A, sigmamean2A, nucsegfailA);
	}
	updateResults();
	print("--- All Nucleus ---");
	for(i= 0; i<rsqA.length; i++){
		print(i+"\t"+rsqA[i]+"\t"+rsqmeanA[i]+"\t"+sigmaA[i]+"\t"+
			sigmameanA[i]+"\t"+rsq2A[i]+"\t"+rsqmean2A[i]+"\t"+sigma2A[i]+"\t"+sigmamean2A[i]+"\t"+
				nucsegfailA[i]);
	}

}

/* 090319test2
var Gparanum1 = 10;	for systematic assesment of the 
var Gparanum2 = 7;
var Gparastep1 = 1; 
var Gparastep2 = 1;
var Gparastart1 = 25;	//090319
*/

/*090319test4

var Gparanum1 = 10;	for systematic assesment of the 
var Gparanum2 = 5;
var Gparastep1 = 5; 
var Gparastep2 = 1;
var Gparastart1 = 30;	//090319
*/

//090319largeregion
/*
var Gparanum1 = 11;	for systematic assesment of the 
var Gparanum2 = 6;
var Gparastep1 = 10; 
var Gparastep2 = 1;
var Gparastart1 = 0;	//090319
*/

//090320smallregion

var Gparanum1 = 20;	for systematic assesment of the 
var Gparanum2 = 4;
var Gparastep1 = 1; 
var Gparastep2 = 1;
var Gparastart1 = 35;	//090319


// first do a dummy search using original macro, then do below
// first round finished on 090306
macro "... systematic search same using ROI info in Results window 090305"{

	if (nResults==0) exit("nothing in results window");

	gausssigma1 = 0;
	gausssigma2 = 0;

	paranum1 = Gparanum1;
	paranum2 = Gparanum2;
	parastep1 = Gparastep1; 
	parastep2 = Gparastep2;
	parastart1 = Gparastart1;	//090319

	paratotal = paranum1 * paranum2;
	nucnum= nResults;

	//rsqA, rsqmeanA, sigmaA, sigmameanA, rsq2A, rsqmean2A, sigma2A, sigmamean2A     
	rsqA = newArray(paratotal*nucnum);
	rsqmeanA = newArray(paratotal*nucnum);	
	sigmaA = newArray(paratotal*nucnum);	
	sigmameanA = newArray(paratotal*nucnum);	
	rsq2A = newArray(paratotal*nucnum);
	rsqmean2A = newArray(paratotal*nucnum);	
	sigma2A = newArray(paratotal*nucnum);	
	sigmamean2A = newArray(paratotal*nucnum);	
	nucsegfailA = newArray(paratotal*nucnum);//090317

	for (s1= 0 ; s1<paranum1; s1+=1){
		for (s2= 0; s2<paranum2; s2+=1){
			// from here, singel iteration
			gausssigma1 = parastart1 + s1 * parastep1;	//090319 modified
			gausssigma2 = s2 * parastep2;
			Gmeascount2 =0;
			for (i=0; i<nucnum; i++){
				print("SIGMA1="+gausssigma1 +"   SIGMA2="+gausssigma2 );
				fileinfostr = getResultLabel(i);
				dapititle = returnDapiTitle(fileinfostr);
				selectWindow(dapititle);
				G_GID = getImageID();
				lamintitle = returnLaminTitle(fileinfostr);
				selectWindow(lamintitle );
				G_RID = getImageID();

				selectImage(G_GID);
				makeRectangle(getResult("roiX", i), getResult("roiY", i),getResult("roiWidth", i),getResult("roiHeight", i));
				RIMstudyCoreSYS(gausssigma1, gausssigma2, i, nucnum, rsqA, rsqmeanA, sigmaA, sigmameanA, rsq2A, rsqmean2A, sigma2A, sigmamean2A, nucsegfailA);
			}
			//setBatchMode("exit and display");
			updateResults();
			// save results window with specific name, sigma values in the name
			resultsFullpath = Gsavepath + "ResultsS"+gausssigma1+"S"+gausssigma2+".xls";	
			saveAs("Measurements", resultsFullpath);

		}
	}

	print("--- All Nucleus ---");
	failnuccounter =  0;
	for(i= 0; i<rsqA.length; i++){
		sigma1value =parastart1 +  floor(i/nucnum/paranum2)*parastep1;
		sigma2value = (floor((i%(nucnum*paranum2))/nucnum)*parastep2);	//check this
		print(sigma1value +"\t"+sigma2value+"\t"+rsqA[i]+"\t"
			+rsqmeanA[i]+"\t"+sigmaA[i]+"\t"+sigmameanA[i]+"\t"+rsq2A[i]+"\t"+
				rsqmean2A[i]+"\t"+sigma2A[i]+"\t"+sigmamean2A[i]+"\t"+
					nucsegfailA[i]);	

/*		print(floor(i/nucnum/paranum1)*parastep1+"\t"+(floor((i%(nucnum*paranum2))/nucnum)*parastep2)+"\t"+rsqA[i]+"\t"
			+rsqmeanA[i]+"\t"+sigmaA[i]+"\t"+sigmameanA[i]+"\t"+rsq2A[i]+"\t"+
				rsqmean2A[i]+"\t"+sigma2A[i]+"\t"+sigmamean2A[i]+"\t"+
					nucsegfailA[i]);	
*/	
		if (nucsegfailA[i]==1) failnuccounter +=1;
	}
	print("");
	print("failed nucleus number: " + failnuccounter );

	print("--- Averaged ---");
	//Array.getStatistics(array, min, max, mean, stdDev)
	rsqmeanstatA = newArray(paratotal);	
	sigmameanstatA = newArray(paratotal);	
	rsqmean2statA = newArray(paratotal);	
	sigmamean2statA = newArray(paratotal);	

	rsqmeanstatsdA = newArray(paratotal);	
	sigmameanstatsdA = newArray(paratotal);	
	rsqmean2statsdA = newArray(paratotal);	
	sigmamean2statsdA = newArray(paratotal);	

	tempstat1preA = newArray(nucnum); //090318 
	tempstat2preA = newArray(nucnum); //090318 
	tempstat3preA = newArray(nucnum); //090318 
	tempstat4preA = newArray(nucnum); //090318 

	tempstat1A = newArray(nucnum);
	tempstat2A = newArray(nucnum);
	tempstat3A = newArray(nucnum);
	tempstat4A = newArray(nucnum);

	counter =0;
	for(i= 0; i<rsqmeanA.length; i+= nucnum){
		validnuccounter = 0;	//090317	
		for(j=0; j<nucnum; j++) {
			if (nucsegfailA[i+j]==0) { 	//090317 take only successfully segmented nuceleus
				tempstat1preA[validnuccounter] = rsqmeanA[i+j];		//bug here 090318 problem with numbering validnuccounter ??
				tempstat2preA[validnuccounter] = sigmameanA[i+j]; 
				tempstat3preA[validnuccounter] = rsqmean2A[i+j]; 
				tempstat4preA[validnuccounter] = sigmamean2A[i+j];
				validnuccounter++;
			} 
		}
		
		tempstat1A = Array.trim(tempstat1preA, validnuccounter); //090318 
		tempstat2A = Array.trim(tempstat2preA, validnuccounter); //090318 
		tempstat3A = Array.trim(tempstat3preA, validnuccounter); //090318 
		tempstat4A = Array.trim(tempstat4preA, validnuccounter); //090318 

		Array.getStatistics(tempstat1A, tmin, tmax, tmean, tstdDev);
		rsqmeanstatA[counter] =tmean;
		rsqmeanstatsdA[counter] =tstdDev;

		Array.getStatistics(tempstat2A, tmin, tmax, tmean, tstdDev);
		sigmameanstatA[counter] =tmean;
		sigmameanstatsdA[counter] =tstdDev;

		Array.getStatistics(tempstat3A, tmin, tmax, tmean, tstdDev);
		rsqmean2statA[counter] =tmean;
		rsqmean2statsdA[counter] =tstdDev;

		Array.getStatistics(tempstat4A, tmin, tmax, tmean, tstdDev);
		sigmamean2statA[counter] =tmean;
		sigmamean2statsdA[counter] =tstdDev; 
		counter++;
	}	
	for(i=0; i<rsqmeanstatA.length; i++) {
		sigma1value = parastart1 + floor(i/paranum2)*parastep1;
		sigma2value = (i - floor(i/paranum2)*paranum2)*parastep2;
		//print(floor(i/paranum1)*parastep1+"\t"+(floor(i%(paranum2))*parastep2)+"\t"+rsqmeanstatA[i]+"\t"+rsqmeanstatsdA[i]+"\t"+sigmameanstatA[i]+"\t"+sigmameanstatsdA[i]+"\t"+rsqmean2statA[i]+"\t"+rsqmean2statsdA[i]+"\t"+sigmamean2statA[i]+"\t"+sigmamean2statsdA[i]+"\t");
		print(sigma1value +"\t"+sigma2value +"\t"+rsqmeanstatA[i]+"\t"+rsqmeanstatsdA[i]+"\t"+sigmameanstatA[i]+"\t"+sigmameanstatsdA[i]+"\t"+rsqmean2statA[i]+"\t"+rsqmean2statsdA[i]+"\t"+sigmamean2statA[i]+"\t"+sigmamean2statsdA[i]+"\t");

	}
	
}
/*
macro "test split"{
	for(j=0; j<nResults;j++)
		print(returnDapiTitle(getResultLabel(j)));
}
*/

//090114
//fileinfostr = dirpath + ";"+dapititle + ";"+lamintitle;
function returnDapiTitle(fileinfostr){
	tempstrA = split(fileinfostr, ";");
	retstr=tempstrA[1];
	return retstr;
}

function returnLaminTitle(fileinfostr){
	tempstrA = split(fileinfostr, ";");
	retstr = tempstrA[2];
	return retstr;
}

function RIMstudyCore(){
	//setBatchMode(true);
	//090108 zscale = Gzscale;
	print("-------------------NUC segmentation-----------------------");
	if (isActive(G_RID)) {
		selectImage(G_GID);
		run("Restore Selection");
	} else {
		selectImage(G_GID);
	}				

	dirpath = getDirectory("image");
	dapititle = getTitle();
	fullpath = getDirectory("image") + getTitle();
	print("Nucleus: "+getTitle());
	//if (Gmeascount2 ==0) run("Clear Results");
	Gmeascount2 +=1;
	nucnameNo = "nuc" + Gmeascount2 ;
	//nucleusname = getString("label for this nucleus", nucnameNo );
	nucleusname = nucnameNo;
	print("Processing for "+nucleusname);
	getSelectionBounds(rx, ry, rw, rh);

	if ((rx==0) && (rw==getWidth())) {	
		Gmeascount2 -=1;
		exit("Need a Rectangular Selection in Nucleus Channel");
	}
	print("ROI position:x,y="+rx+", " +ry+" w,h"+rw+", "+rh );

	//setBatchMode(true);
	run("Duplicate...", "title=[NucleusCrop Original] duplicate"); // for intensity 
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	nucOrgID = getImageID();

	maxintslice = SetToHighestIntensitySlice();
	print("max int slice = "+maxintslice );

	run("Duplicate...", "title=[Nucleus_2D]");	//2d
	nuc2DID = getImageID();

	run("Duplicate...", "title=[Nucleus_Segmentation]");	//2d
	//run("Duplicate...", "title=[Nucleus_Segmentation] duplicate");	//3d
	nucID = getImageID();

//***************************************************************** THIS IS THE PART where to study the segmentation strategy. 
	//StefanSegmentation();
	//KotasSegmentation2D(GThNucL, GThNucH);		//old method, 2008 sept to dec. Threshold values determined by full frame and stroed as global variable
	//KotasSegmentation090108();			//090109
	//KotasSegmentation090108better();			//090109
	//KotasSegmentation090113() ;				//090113
	//KotasSegmentation4();	//out on 20110127
	//KotasSegmentationEval(1); //strategy5
	//KotasSegmentationEval(2); //strategy6
	//KotasSegmentationEval(3); //strategy7
	//KotasSegmentationEval(4); //strategy8
	//KotasSegmentationEval(6); //strategy9
	//KotasSegmentationEval(8); //strategy10
	//KotasSegmentationEval(12); //strategy11
	KotasSegmentationEval2para(37, 1); //in on 20110127
	//SegmentationChooser();	//out on 20110127
	//run("Fill Holes"); commented out 090305

//*****************************************************************
	//get centroid
/*
	run("Set Measurements...", "area centroid center integrated redirect=None decimal=3");
	run("Analyze Particles...", "size=1000-Infinity circularity=0.00-1.00 show=Nothing display clear");
	if (nResults!=1) {
		exit("more than one nucleus signal, or no signal: check for the noise");
	}
	print(getResult("X", 0));
	print(getResult("Y", 0));
*/
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
	centroidx = xpossum /poscounter;
	centroidy = ypossum /poscounter;
	print("DAPI centroid:"+centroidx+","+centroidy);
	
	//then there should be binary edge detection routine: plot profile radially from centroid, then detect the decrease to 0. 
	//080108 cancel the above process: make an outline, and convert it to numerical array of outline coordinates
	// this is because of the complex edge shape is sometimes expected. 

	selectImage(nucID );
	run("Duplicate...", "title=[NucleusdapiRim] duplicate");
	run("Erode"); //one pixel inside
	run("Outline"); //but then recovers.
	NucOutlineID = getImageID();
	// convert to numerical arrrays
	poscounter=ReturnNone0counts();
	xposA=newArray(poscounter);
	yposA=newArray(poscounter);
	storeNone0coords(xposA, yposA);	//used later, to measure distance with a single position from Lamin ring

// ------------ Rim detection using 
	selectImage(G_RID);	//
	lamintitle = getTitle();
	makeRectangle(rx, ry, rw, rh);
	run("Duplicate...", "title=[RimCropOriginal] duplicate"); // for intensity 
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	RimOrgID = getImageID();

	setSlice(maxintslice); 
	//do radial measurements to detect the rim
	degincrements = 10;
	rimposxA = newArray(360/degincrements);
	rimposyA = newArray(360/degincrements);

	RimDetector(rimposxA, rimposyA, centroidx , centroidy , degincrements);

	run("Select None");
	run("Duplicate...", "title=[Lamin2D]");
	Lamin2DID = getImageID();		

	run("Duplicate...", "title=detected_rim");
	Rim2DID = getImageID();		
	run("RGB Color");
	for(i=0; i<rimposxA.length; i++){
		setColor(255, 0, 0);
		if (i==0) 
			drawLine(rimposxA[rimposxA.length-1], rimposyA[rimposyA.length-1], rimposxA[i], rimposyA[i]);
		else
			drawLine(rimposxA[i-1], rimposyA[i-1], rimposxA[i], rimposyA[i]);
	}

	//calculate the deviation between two protocols. 
	minimposA = newArray(rimposxA.length);
	minimdistA = newArray(rimposxA.length);
	calcNearestLaminEdge(minimposA, minimdistA, rimposxA, rimposyA, xposA, yposA);

	//calculate the deviation between two protocols. 2nd way, radial axis into consideration 
	dapiedgeposxA = newArray(rimposxA.length);
	dapiedgeposyA = newArray(rimposxA.length);
	minimdist2A = newArray(rimposxA.length);
	calcDeviationradially(rimposxA, rimposyA, nucID,centroidx, centroidy, dapiedgeposxA, dapiedgeposyA, minimdist2A);

	selectImage(nucID);
	run("Duplicate...", "title=rim_compare");
	RimCompareID = getImageID();		
	run("RGB Color");
	for(i=0; i<rimposxA.length; i++){
		setColor(255, 0, 0);
		if (i==0) 
			drawLine(rimposxA[rimposxA.length-1], rimposyA[rimposyA.length-1], rimposxA[i], rimposyA[i]);
		else
			drawLine(rimposxA[i-1], rimposyA[i-1], rimposxA[i], rimposyA[i]);
	}
	for(i=0; i<rimposxA.length; i++){
		setColor(0, 255, 255);
		drawLine(rimposxA[i], rimposyA[i], dapiedgeposxA[i], dapiedgeposyA[i]);
	}
	for(i=0; i<rimposxA.length; i++){
		setColor(0, 0, 255);
		drawLine(rimposxA[i], rimposyA[i], xposA[minimposA[i]], yposA[minimposA[i]]);
	}

	op = "red=[Lamin2D] green=*None* blue=[Nucleus_2D] gray=*None* keep";
	run("Merge Channels...", op);
	rename(nucleusname +"_RimMerged.tif");
	Orig2chID = getImageID();



	//statistics
	sigmaRsq =0;
	for(i=0; i<minimdistA.length; i++)  sigmaRsq += pow(minimdistA[i],2);
	meanSigmaRsq = sigmaRsq / minimdistA.length;

	sigma = 0;
	for(i=0; i<minimdistA.length; i++){
		centdapi = Return2Ddist(centroidx , centroidy , xposA[minimposA[i]], yposA[minimposA[i]]);
		centlami = Return2Ddist(centroidx , centroidy , rimposxA[i], rimposyA[i]);
		if (centlami>centdapi) sigma -= minimdistA[i];	//dapi edge inside Lamin ring
		else
		sigma += minimdistA[i];	//dapi edge inside DAPI ring
	}

	// deviation, radial method 090115

	sigmaRsq2 =0;
	for(i=0; i<minimdist2A.length; i++)  sigmaRsq2 += pow(minimdist2A[i],2);
	meanSigmaRsq2 = sigmaRsq2 / minimdist2A.length;

	sigma2 = 0;
	for(i=0; i<minimdist2A.length; i++) sigma2 += minimdist2A[i];	//dapi edge inside DAPI ring
	simga2mean =sigma2/minimdist2A.length;

	print("< minimum distance deviation >");
	print("- R squared = "+ sigmaRsq);
	print("-- R squared mean = "+ meanSigmaRsq);
	print("- Simple Sigma = "+ sigma);
	print("-- Simple Sigma mean = "+ sigma/minimdistA.length);

	print("<radial deviation>");
	print("- R squared = "+ sigmaRsq2);
	print("-- R squared mean = "+ meanSigmaRsq2);
	print("- Simple Sigma = "+ sigma2);
	print("-- Simple Sigma mean = "+ simga2mean );


	//results window
/*	setResult("nucID", Gmeascount2-1,  Gmeascount2);
	setResult("roiX", Gmeascount2-1, rx);
	setResult("roiY", Gmeascount2-1, ry);
	setResult("roiWidth", Gmeascount2-1, rw);
	setResult("roiHeight", Gmeascount2-1, rh);

	setResult("Rsq", Gmeascount2-1, sigmaRsq);
	setResult("RsqMean", Gmeascount2-1, meanSigmaRsq);
	setResult("Sigma", Gmeascount2-1, sigma);
	setResult("SigmaMean", Gmeascount2-1, sigma/minimdistA.length);

	setResult("Rsq2", Gmeascount2-1, sigmaRsq2);
	setResult("RsqMean2", Gmeascount2-1, meanSigmaRsq2);
	setResult("Sigma2", Gmeascount2-1, sigma2);
	setResult("SigmaMean2", Gmeascount2-1, simga2mean );

	fileinfostr = dirpath + ";"+dapititle + ";"+lamintitle;
	setResult("Label", Gmeascount2-1, fileinfostr);
*/
	currentResultcount=nResults;
	setResult("nucID", currentResultcount,  Gmeascount2);
	setResult("roiX", currentResultcount, rx);
	setResult("roiY", currentResultcount, ry);
	setResult("roiWidth", currentResultcount, rw);
	setResult("roiHeight", currentResultcount, rh);

	setResult("Rsq", currentResultcount, sigmaRsq);
	setResult("RsqMean", currentResultcount, meanSigmaRsq);
	setResult("Sigma", currentResultcount, sigma);
	setResult("SigmaMean", currentResultcount, sigma/minimdistA.length);

	setResult("Rsq2", currentResultcount, sigmaRsq2);
	setResult("RsqMean2", currentResultcount, meanSigmaRsq2);
	setResult("Sigma2", currentResultcount, sigma2);
	setResult("SigmaMean2", currentResultcount, simga2mean );

	fileinfostr = dirpath + ";"+dapititle + ";"+lamintitle;
	setResult("Label", currentResultcount, fileinfostr);
	updateResults();

	//Merging the resultimages
	op = "width="+rw*3+" height="+rh+" position=Center-Left zero";
	run("Canvas Size...", op);
	selectImage(Rim2DID); run("Select All"); run("Copy");
	selectImage(Orig2chID); makeRectangle(rw, 0, rw, rh); run("Paste");
	selectImage(RimCompareID); run("Select All"); run("Copy");
	selectImage(Orig2chID); makeRectangle(2*rw, 0, rw, rh); run("Paste");

	// printing info
	op = "width="+rw*3+" height="+(rh+45)+" position=Bottom-Left zero";
	run("Canvas Size...", op);
	setFont("SansSerif", 10);
	//setJustification("left");
	 setColor(255, 255, 255);
	drawString(fullpath, 2, 10);
	roipos = "roi @ (" +rx+ ", " +ry+ ", " +rw+ ", "+rh + ")";
	drawString(roipos, 2, 21);
	statsstring ="R^2 = "+ d2s(sigmaRsq, 1) +"  R^2 mean = "+ d2s(meanSigmaRsq, 1)+ "Sig = "+ d2s(sigma, 1) + "  Sig Mean = "+ d2s(sigma/minimdistA.length, 1);
	drawString(statsstring , 2, 32);
	//statsstring ="Sig = "+ d2s(sigma, 1) + "  Sig Mean = "+ d2s(sigma/minimdistA.length, 1);
	statsstring ="R^2 = "+ d2s(sigmaRsq2, 1) +"  R^2 mean = "+ d2s(meanSigmaRsq2, 1)+ "Sig = "+ d2s(sigma2, 1) + "  Sig Mean = "+ d2s(simga2mean, 1);
	drawString(statsstring , 2, 43);
	
	saveAs("Tiff", Gsavepath+getTitle());


	//closing windows
	selectImage(nucOrgID); close();
	selectImage(RimOrgID); close();
	selectImage(NucOutlineID); close();
	selectImage(nucID); close();
	selectImage(nuc2DID); close(); 
	selectImage(Lamin2DID); close();

	selectImage(Rim2DID); close();
	selectImage(RimCompareID); close();
	setBatchMode("exit and display");

	//selectImage(Orig2chID ); close();	//for doing quick evaluation

}

function Return2Ddist(x1, y1, x2, y2){
	return sqrt(pow((x1 -x2), 2) + pow((y1 -y2), 2));
}

function calcNearestLaminEdge(minimposA, minimdistA, rimposxA, rimposyA, xposA, yposA){
	distlistA=newArray(xposA.length);
	for(i=0; i<rimposxA.length; i++){
	
		for(j=0; j<xposA.length; j++)
			distlistA[j] = sqrt(pow((xposA[j] -rimposxA[i]), 2) + pow((yposA[j] -rimposyA[i]), 2)); 
		minimdistA[i] = K_retrunArrayMin(distlistA);
		minimposA[i] = K_retrunArrayMinPosition(distlistA);
	}
}

function K_retrunArrayMin(aA) {
	aA_min=500000; //LIB
	for (k=0;k<aA.length;k++) if (aA_min>aA[k]) aA_min=aA[k];
	return aA_min;
 } 

//returns minimum position
function K_retrunArrayMinPosition(aA) {
	aA_min=500000; //LIB
	minpos =0;
	for (k=0;k<aA.length;k++) if (aA_min>aA[k]) {
		aA_min=aA[k];
		minpos = k;
	}
	return minpos ;
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

//090109
function ReturnNone0counts(){
	getDimensions(ww, hh, channels, slices, frames);
	poscounter=0;
	for (i=0; i<hh; i++)
		for (j=0; j<ww; j++)
			if (getPixel(j, i)>0) poscounter+=1;
	return poscounter;
}

//090109
function storeNone0coords(xposA, yposA){
	getDimensions(ww, hh, channels, slices, frames);
	poscounter=0;
	for (i=0; i<hh; i++)
		for (j=0; j<ww; j++)
			if (getPixel(j, i)>0) {
				xposA[poscounter]=j;
				yposA[poscounter]=i;
				poscounter++;
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
}n

//090115
function calcDeviationradially(rimposxA, rimposyA, nucID,centx, centy, dapiedgeposxA, dapiedgeposyA, minimdist2A) {
	selectImage(nucID);
	for(i=0; i<rimposxA.length; i++) {
		//print("deg"+i*10);
		minimdist2A[i] = RadialDeviation(rimposxA[i], rimposyA[i], centx, centy, dapiedgeposxA, dapiedgeposyA, i);
		//print("dist2="+minimdist2A[i]);
	}
}


//****************************************SEGMENTATION STRATEEGIES***********************************************

function SegmentationChooser(){

	//StefanSegmentation();
	//KotasSegmentation2D(GThNucL, GThNucH);		//old method, 2008 sept to dec. Threshold values determined by full frame and stroed as global variable
	//KotasSegmentation090108();			//090109
	//KotasSegmentation090108better();			//090109
	//KotasSegmentation090113() ;				//090113
	//KotasSegmentation4();
	//KotasSegmentationEval(1); //strategy5
	//KotasSegmentationEval(2); //strategy6
	//KotasSegmentationEval(3); //strategy7
	//KotasSegmentationEval(4); //strategy8
	//KotasSegmentationEval(6); //strategy9
	//KotasSegmentationEval(8); //strategy10
	//KotasSegmentationEval(12); //strategy11
	run("Fill Holes");

}

//090303
function ExploreSegmentations(gausssigma1, gausssigma2){
		KotasSegmentationEval2para(gausssigma1, gausssigma2);
}



// this is theinitial version, used between 0809 and 0812. 
// threshold level is automatically set using FULL frame (including many nucleus).
// --> this has problem, when nucleus DAPI intensity is not saturated. 
function KotasSegmentation2D(thresLow, threshigh) {
	//run("Gaussian Blur...", "sigma=3 stack");
	run("Gaussian Blur...", "sigma=3");
	setThreshold(GThNucL, GThNucH);
	run("Convert to Mask", "  black");
}

//090109
// threshold determined by individual nucleus.

//  Gauss blur 3 -> Mixture Modeling
function KotasSegmentation090108() {
	run("Gaussian Blur...", "sigma=3 stack");
	run("MultiThresholder", "Mixture Modeling");
	getThreshold(lower, upper);
	setThreshold(upper+1, 255);
	//setThreshold(GThNucL, GThNucH);
	run("Convert to Mask", "  black");
}

//090109 threshold level is determined individually. 
//larger Gaussian size enables better segmentation results. 

// find threshold (Gauss blur 5 -> Otsu thresholding) -> actual segmentation done on blur 3
function KotasSegmentation090108better() {
	currentID = getImageID();
	run("Duplicate...", "title=[tempforThresholding]"); // for evaluation 	
	run("Gaussian Blur...", "sigma=5");
	run("MultiThresholder", "Otsu");
	getThreshold(lower, upper);
	close();
	selectImage(currentID);
	run("Gaussian Blur...", "sigma=3");
	setThreshold(upper, 255);
	//setThreshold(GThNucL, GThNucH);
	run("Convert to Mask", "  black");
}

// find threshold (Gauss blur 3 two times -> Otsu thresholding) -> actual segmentation done on blur 3

function KotasSegmentation090113() {
	currentID = getImageID();
	run("Duplicate...", "title=[tempforThresholding]"); // for evaluation 	
	run("Gaussian Blur...", "sigma=3");
	run("Gaussian Blur...", "sigma=3");
	run("MultiThresholder", "Otsu");
	getThreshold(lower, upper);
	close();
	selectImage(currentID);
	run("Gaussian Blur...", "sigma=3");
	setThreshold(upper, 255);
	//setThreshold(GThNucL, GThNucH);
	run("Convert to Mask", "  black");
}

// find threshold (Gauss blur 8 -> Otsu thresholding) -> actual segmentation done on blur 2
function KotasSegmentation4() {
	currentID = getImageID();
	run("Duplicate...", "title=[tempforThresholding]"); // for evaluation 	
	run("Gaussian Blur...", "sigma=8");
	run("MultiThresholder", "Otsu");
	getThreshold(lower, upper);
	close();
	selectImage(currentID);
	run("Gaussian Blur...", "sigma=2");
	setThreshold(upper, 255);
	run("Convert to Mask", "  black");
}

function KotasSegmentationEval(gausssigma1) {
	op = "sigma="+gausssigma1;
	run("Gaussian Blur...", op);
	run("MultiThresholder", "Otsu");
	getThreshold(lower, upper);
	setThreshold(upper, 255);
	run("Convert to Mask", "  black");
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

//-------------------

//090305
//090311 gausssigma1 = -1, then do old segmentation method
//090421 scaling
function RIMstudyCoreSYS(gausssigma1, gausssigma2, iteration, nucnum, rsqA, rsqmeanA, sigmaA, sigmameanA, rsq2A, rsqmean2A, sigma2A, sigmamean2A, nucsegfailA){
	setBatchMode(true);
	//090108 zscale = Gzscale;

	paranum1 = Gparanum1;
	paranum2 = Gparanum2;
	parastep1 = Gparastep1; 
	parastep2 = Gparastep2;
	paratotal = paranum1 * paranum2;

	parastart1 = Gparastart1;	//090319

	print("-------------------NUC segmentation-----------------------");
	selectImage(G_GID);
	XYscaleSetter(); //090421
	if (gausssigma1 == -1) getAutoThresholdNucleusNoWindowsetter(); //090308 only for the segmentation strategy in 2008
	dirpath = getDirectory("image");
	dapititle = getTitle();
	fullpath = getDirectory("image") + getTitle();
	print("Window: "+getTitle());
	//if (Gmeascount2 ==0) run("Clear Results");
	Gmeascount2 +=1;
	nucnameNo = "nuc" + Gmeascount2 ;
	//nucleusname = getString("label for this nucleus", nucnameNo );
	nucleusname = nucnameNo;
	print("Processing for "+nucleusname);
	getSelectionBounds(rx, ry, rw, rh);

	if ((rx==0) && (rw==getWidth())) {	
		Gmeascount2 -=1;
		exit("Need a Rectangular Selection in Nucleus Channel");
	}
	print("ROI position:x,y="+rx+", " +ry+" w,h"+rw+", "+rh );

	//setBatchMode(true);
	run("Duplicate...", "title=[NucleusCrop Original] duplicate"); // for intensity 
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	nucOrgID = getImageID();

	maxintslice = SetToHighestIntensitySlice();
	print("max int slice = "+maxintslice );

	run("Duplicate...", "title=[Nucleus_2D]");	//2d
	nuc2DID = getImageID();

	run("Duplicate...", "title=[Nucleus_Segmentation]");	//2d
	//run("Duplicate...", "title=[Nucleus_Segmentation] duplicate");	//3d
	nucID = getImageID();
	setBatchMode("exit and display");
//***************************************************************** THIS IS THE PART where to study the segmentation strategy. 
	thresholdLow = KotasSegmentationEval2para(gausssigma1, gausssigma2);	//090305
	//KotasSegmentation2D(GThNucL, GThNucH); //090308	old strategy. Image should be gauss=3 before processing. 
//*****************************************************************
	setBatchMode(true);
	//get centroid
/*
	run("Set Measurements...", "area centroid center integrated redirect=None decimal=3");
	run("Analyze Particles...", "size=1000-Infinity circularity=0.00-1.00 show=Nothing display clear");
	if (nResults!=1) {
		exit("more than one nucleus signal, or no signal: check for the noise");
	}
	print(getResult("X", 0));
	print(getResult("Y", 0));
	//run("Analyze Particles...", "size=2-Infinity circularity=0.00-1.00 show=Nothing exclude summarize add");
	//print(roiManager("count"));
	//roiManager("reset");
*/
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
	centroidx = xpossum /poscounter;
	centroidy = ypossum /poscounter;

	nucsegmentationFailflag = 0;	//090317
	if (poscounter==0) { 	//090317 saving none segmentetion failure
		print("DAPI centroid: NaN, could not be calculated. Possible faiilure in Nucelus Segmentation");
		centroidx = ww/2;	//dummmy. center of the image
		centroidy = hh/2;	//dummmy. center of the image
		nucsegmentationFailflag = 1;	//090317
	} else {
		print("DAPI centroid:"+centroidx+","+centroidy);
	}
	//then there should be binary edge detection routine: plot profile radially from centroid, then detect the decrease to 0. 
	//080108 cancel the above process: make an outline, and convert it to numerical array of outline coordinates
	// this is because of the complex edge shape is sometimes expected. 

	selectImage(nucID );
	run("Duplicate...", "title=[NucleusdapiRim] duplicate");
	run("Outline"); //but then recovers.
	NucOutlineID = getImageID();
	// convert to numerical arrrays
	poscounter=ReturnNone0counts();
	//090315 should implement situations when segmentation failed, and no nuceleus area found (poscounter=0). 
	//	place some flag in the results, so that the value will not be included in the measurement, and count the number of failure. 
	if (poscounter>0) {		//poscounter=0 if there is no segmented nucleus
		xposA=newArray(poscounter);
		yposA=newArray(poscounter);
		storeNone0coords(xposA, yposA);	//used later, to measure distance with a single position from Lamin ring
	}	// case of poscounter 0, xosA yposA filling process comes later 

	print("-------------------RIM segmentation-----------------------");
// ------------ Rim detection using 
	selectImage(G_RID);	//
	lamintitle = getTitle();
	print("Window: "+lamintitle);
	makeRectangle(rx, ry, rw, rh);
	run("Duplicate...", "title=[RimCropOriginal] duplicate"); // for intensity 
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	RimOrgID = getImageID();

	setSlice(maxintslice); 
	//do radial measurements to detect the rim
	degincrements = 10;
	rimposxA = newArray(360/degincrements);
	rimposyA = newArray(360/degincrements);

	RimDetector(rimposxA, rimposyA, centroidx , centroidy , degincrements);

	Array.getStatistics(rimposxA, xmin, xmax, xmean, xstdDev);	//090317
	Array.getStatistics(rimposyA, ymin, ymax, ymean, ystdDev);	//090317
	if (poscounter==0) {		//poscounter=0 if there is no segmented nucleus 	//090317
		centroidx = xmean; 	// window nenter replaced to lamin rim center. 
		centroidy = ymean;  	// window nenter replaced to lamin rim center. 
		xposA=newArray(1);
		yposA=newArray(1);
		xposA[0]=centroidx ;
		yposA[0]=centroidy ;
	}	

	run("Select None");
	run("Duplicate...", "title=[Lamin2D]");
	Lamin2DID = getImageID();		

	run("Duplicate...", "title=detected_rim");
	Rim2DID = getImageID();		
	run("RGB Color");
	for(i=0; i<rimposxA.length; i++){
		setColor(255, 0, 0);
		if (i==0) 
			drawLine(rimposxA[rimposxA.length-1], rimposyA[rimposyA.length-1], rimposxA[i], rimposyA[i]);
		else
			drawLine(rimposxA[i-1], rimposyA[i-1], rimposxA[i], rimposyA[i]);
	}

	//calculate the deviation between two protocols. 
	minimposA = newArray(rimposxA.length);
	minimdistA = newArray(rimposxA.length);
	if (poscounter>0) {		//poscounter=0 if there is no segmented nucleus 	//090317	
		calcNearestLaminEdge(minimposA, minimdistA, rimposxA, rimposyA, xposA, yposA);
	} else { 	// 090317
		//xposA, yposA are nucleus positive picels positions--> so the distance will be from centroid of the rim.
		for(i=0; i<rimposxA.length; i++){
			minimposA[i] = 0;
			minimdistA[i] = sqrt( pow((rimposxA[i] - centroidx), 2) + pow((rimposyA[i] - centroidy), 2)  ) ;
		}
	}
	//calculate the deviation between two protocols. 2nd way, radial axis into consideration 
	dapiedgeposxA = newArray(rimposxA.length);
	dapiedgeposyA = newArray(rimposxA.length);
	minimdist2A = newArray(rimposxA.length);
	if (poscounter>0) {		//poscounter=0 if there is no segmented nucleus 	//090317	
		calcDeviationradially(rimposxA, rimposyA, nucID,centroidx, centroidy, dapiedgeposxA, dapiedgeposyA, minimdist2A);
	} else {		// when there is no nucleus, calculate distance from centroid 090317
		for (i=0; i<rimposxA.length; i++) {
			dapiedgeposxA[i] = centroidx;
			dapiedgeposyA[i] = centroidy;
			minimdist2A[i] = sqrt( pow((rimposxA[i] - centroidx), 2) + pow((rimposyA[i] - centroidy), 2)  ) ;
		}
	}
	
	//090324 return mean radius of lamin rim	
	nucradiusA = newArray(rimposxA.length);
	for(i=0; i<rimposxA.length; i++) {
		nucradiusA[i] = Return2Ddist(rimposxA[i], rimposyA[i], centroidx, centroidy);
	}
	Array.getStatistics(nucradiusA, nucmin, nucmax, nucmean, nucstdDev);
	laminnucradius = nucmean;

	selectImage(nucID);
	run("Duplicate...", "title=rim_compare");
	RimCompareID = getImageID();		
	run("RGB Color");
	for(i=0; i<rimposxA.length; i++){
		setColor(255, 0, 0);
		if (i==0) 
			drawLine(rimposxA[rimposxA.length-1], rimposyA[rimposyA.length-1], rimposxA[i], rimposyA[i]);
		else
			drawLine(rimposxA[i-1], rimposyA[i-1], rimposxA[i], rimposyA[i]);
	}
	for(i=0; i<rimposxA.length; i++){
		setColor(0, 255, 255);
		drawLine(rimposxA[i], rimposyA[i], dapiedgeposxA[i], dapiedgeposyA[i]);
	}
	for(i=0; i<rimposxA.length; i++){
		setColor(0, 0, 255);
		drawLine(rimposxA[i], rimposyA[i], xposA[minimposA[i]], yposA[minimposA[i]]);
	}

	op = "red=[Lamin2D] green=*None* blue=[Nucleus_2D] gray=*None* keep";
	run("Merge Channels...", op);
	rename(nucleusname +"_RimMerged.tif");
	Orig2chID = getImageID();


	setBatchMode("exit and display");

	//statistics
	sigmaRsq =0;
	for(i=0; i<minimdistA.length; i++)  sigmaRsq += pow(minimdistA[i],2);
	meanSigmaRsq = sigmaRsq / minimdistA.length;

	sigma = 0;
	for(i=0; i<minimdistA.length; i++){
		centdapi = Return2Ddist(centroidx , centroidy , xposA[minimposA[i]], yposA[minimposA[i]]);
		centlami = Return2Ddist(centroidx , centroidy , rimposxA[i], rimposyA[i]);
		if (centlami>centdapi) sigma -= minimdistA[i];	//dapi edge inside Lamin ring
		else
		sigma += minimdistA[i];	//dapi edge inside DAPI ring
	}

	// deviation, radial method 090115

	sigmaRsq2 =0;
	for(i=0; i<minimdist2A.length; i++)  sigmaRsq2 += pow(minimdist2A[i],2);
	meanSigmaRsq2 = sigmaRsq2 / minimdist2A.length;

	sigma2 = 0;
	for(i=0; i<minimdist2A.length; i++) sigma2 += minimdist2A[i];	//dapi edge inside DAPI ring
	simga2mean =sigma2/minimdist2A.length;

	if (nucsegmentationFailflag) print("xxxxxxxxx No Nucleus Segmented!!! rim centroid used as reference.");

	// ---- scaling by um---- 090422

	sigmaRsq = sigmaRsq * GXYscale * GXYscale;
 	meanSigmaRsq = meanSigmaRsq * GXYscale * GXYscale;
	sigma = sigma  * GXYscale;
	sigmaRsq2 = sigmaRsq2 * GXYscale * GXYscale;
	meanSigmaRsq2 = meanSigmaRsq2  * GXYscale * GXYscale;
 	sigma2 = sigma2  * GXYscale;
	simga2mean = simga2mean * GXYscale;
	laminnucradius = laminnucradius  * GXYscale;
	// --- end of scaling 
 
	print("< minimum distance deviation >");
	print("- R squared = "+ sigmaRsq);
	print("-- R squared mean = "+ meanSigmaRsq);
	print("- Simple Sigma = "+ sigma);
	print("-- Simple Sigma mean = "+ sigma/minimdistA.length);

	print("<radial deviation>");
	print("- R squared = "+ sigmaRsq2);
	print("-- R squared mean = "+ meanSigmaRsq2);
	print("- Simple Sigma = "+ sigma2);
	print("-- Simple Sigma mean = "+ simga2mean );


	//results window
	setResult("nucID", Gmeascount2-1,  Gmeascount2);
	setResult("roiX", Gmeascount2-1, rx);
	setResult("roiY", Gmeascount2-1, ry);
	setResult("roiWidth", Gmeascount2-1, rw);
	setResult("roiHeight", Gmeascount2-1, rh);

	setResult("Rsq", Gmeascount2-1, sigmaRsq);
	setResult("RsqMean", Gmeascount2-1, meanSigmaRsq);
	setResult("Sigma", Gmeascount2-1, sigma);
	setResult("SigmaMean", Gmeascount2-1, sigma/minimdistA.length);

	setResult("Rsq2", Gmeascount2-1, sigmaRsq2);
	setResult("RsqMean2", Gmeascount2-1, meanSigmaRsq2);
	setResult("Sigma2", Gmeascount2-1, sigma2);
	setResult("SigmaMean2", Gmeascount2-1, simga2mean );

	setResult("laminRadius", Gmeascount2-1, laminnucradius);
	setResult("NucSegmfail", Gmeascount2-1, nucsegmentationFailflag);
	setResult("ThresholdLow", Gmeascount2-1, nucsegmentationFailflag);

	fileinfostr = dirpath + ";"+dapititle + ";"+lamintitle;
	setResult("Label", Gmeascount2-1, fileinfostr);
	updateResults();

	// results to array

//	aindex =((gausssigma1/parastep1)*paranum1 + (gausssigma2/parastep2))*nucnum+iteration;  //bug 090319
	
	if ((Gparanum1 ==1) && (Gparanum2 == 1)) {
		aindex =iteration;  //090324
	} else {
		s1 =((gausssigma1-parastart1)/parastep1);  //090319
		s2 =(gausssigma2/parastep2);  //090319
 		aindex =s1*paranum2 *nucnum + s2*nucnum+iteration;  //090319
	}
	
	rsqA[aindex] = sigmaRsq;
	rsqmeanA[aindex]= meanSigmaRsq;
	sigmaA[aindex]=sigma;
	sigmameanA[aindex]=sigma/minimdistA.length;
	rsq2A[aindex]=sigmaRsq2;
	rsqmean2A[aindex]=meanSigmaRsq2;
	sigma2A[aindex]=sigma2;
	sigmamean2A[aindex]=simga2mean ; 
	nucsegfailA[aindex] = nucsegmentationFailflag;

	//Merging the resultimages
	op = "width="+rw*3+" height="+rh+" position=Center-Left zero";
	run("Canvas Size...", op);
	selectImage(Rim2DID); run("Select All"); run("Copy");
	selectImage(Orig2chID); makeRectangle(rw, 0, rw, rh); run("Paste");
	selectImage(RimCompareID); run("Select All"); run("Copy");
	selectImage(Orig2chID); makeRectangle(2*rw, 0, rw, rh); run("Paste");

	// printing info in the image
	op = "width="+rw*3+" height="+(rh+45)+" position=Bottom-Left zero";
	run("Canvas Size...", op);
	setFont("SansSerif", 10);
	//setJustification("left");
	 setColor(255, 255, 255);
	drawString(fullpath, 2, 10);
	roipos = "roi @ (" +rx+ ", " +ry+ ", " +rw+ ", "+rh + ")";
	drawString(roipos, 2, 21);
	statsstring ="R^2 = "+ d2s(sigmaRsq, 1) +"  R^2 mean = "+ d2s(meanSigmaRsq, 1)+ "Sig = "+ d2s(sigma, 1) + "  Sig Mean = "+ d2s(sigma/minimdistA.length, 1);
	drawString(statsstring , 2, 32);
	//statsstring ="Sig = "+ d2s(sigma, 1) + "  Sig Mean = "+ d2s(sigma/minimdistA.length, 1);
	statsstring ="R^2 = "+ d2s(sigmaRsq2, 1) +"  R^2 mean = "+ d2s(meanSigmaRsq2, 1)+ "Sig = "+ d2s(sigma2, 1) + "  Sig Mean = "+ d2s(simga2mean, 1);
	drawString(statsstring , 2, 43);
	//setBatchMode("exit and display");
	rename(getTitle()+"s"+gausssigma1+"_s"+gausssigma2+".tif");
	saveAs("Tiff", Gsavepath+getTitle());
	close(); // no window left afterwards.


	//closing windows
	selectImage(nucOrgID); close();
	selectImage(RimOrgID); close();
	selectImage(NucOutlineID); close();
	selectImage(nucID); close();
	selectImage(nuc2DID); close(); 
	selectImage(Lamin2DID); close();

	selectImage(Rim2DID); close();
	selectImage(RimCompareID); close();

	//setBatchMode("exit and display");

	//selectImage(Orig2chID ); close();	//for doing quick evaluation

}



//****************************************SEGMENTATION STRATEEGIES END***********************************************
