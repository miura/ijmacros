/* Kota Miura 
070222 
	for Janina, counting dots overlapped in two channels. 
070822 
	add modified macro for muscle signal. Image threshold muscle channle, 
	use it as mask and count the number of caspace positive dots. 

	- series loading is different, creates a single stack with both channles. so new macro for comberting it to RGB stack
	- dialog window for threshold setting
*/

var G_lower=50;
var G_g_lower = 63; 
var G_r_lower = 105; 
var Gsizemin =0;
var Gsizemax =10;

var Gsizefilterswitch=0;

/*
macro "set Lower Threshold for Green Channel" {
	lower=getNumber("Green Channel Lower", G_g_lower);
	G_g_lower=lower;
}

macro "set Lower Threshold for Red Channel" {
	lower=getNumber("Red Channel Lower", G_r_lower);
	G_r_lower=lower;
}
*/

macro "Set Parameters [F9]" {
	setthresholds070822();
}

function setthresholds070822() {

 	Dialog.create("Set Threshold");
	Dialog.addMessage("Set Lower Threshold Value for each Channel");
	Dialog.addNumber("Green Channel",  G_g_lower  );
	Dialog.addNumber("Red Channel", G_r_lower );
	Dialog.addMessage("Dot Size Filtering");
	Dialog.addCheckbox(" filter dots by size [pixels]", Gsizefilterswitch);
 	Dialog.show();
	G_g_lower =Dialog.getNumber();
	G_r_lower =Dialog.getNumber();
	Gsizefilterswitch=Dialog.getCheckbox();
	if (Gsizefilterswitch) {
		Dialog.create("Set Dot Filter");
		Dialog.addMessage("Set Min and Max dot sizes in pixels");
		Dialog.addNumber("Size Minimum",  Gsizemin   );
		Dialog.addNumber("Size maximum", Gsizemax  );
	 	Dialog.show();
		Gsizemin =Dialog.getNumber();
		Gsizemax =Dialog.getNumber();	
	}
}


macro "-"{}

//must have "SliceRemover plugin"
macro "BW 2ch stack to RGB merged [F12]" {
	if (nSlices==1) exit("need a stack");
	setBatchMode(true);
	RchID = getImageID();
	rename("Rch.tif");
	run("Duplicate...", "title=Gch.tif duplicate");
	GchID = getImageID();
	op = "first=1 last="+nSlices+" increment=2";
	run("Slice Remover", op);

	selectImage(RchID);
	op = "first=2 last="+nSlices+" increment=2";
	run("Slice Remover", op);
	run("RGB Merge...", "red=Rch.tif green=Gch.tif blue=*None*");// keep");
	setBatchMode("exit and display");
}

macro "-"{}

macro "Measure Colocalized Dots [f1]" {

	open();
	originalRGBstackTitle=getTitle();
	sourcepath=getDirectory("image");

	run("RGB Split");
	
	Rtitle=originalRGBstackTitle+" (red)";
	Gtitle=originalRGBstackTitle+" (green)";
	Btitle=originalRGBstackTitle+" (blue)";

	selectWindow(Rtitle);
	setThreshold(G_r_lower,255);
	run("Convert to Mask", "stack");

	selectWindow(Gtitle);
	setThreshold(G_g_lower,255);
	run("Convert to Mask", "stack");

	selectWindow(Btitle);
	close();

	imageCalculator("AND create stack", Rtitle,Gtitle);
	colocalizedStackID=getImageID();
	coloc_name=getTitle();
	colocalized_dots=0;	
	for(i=0; i<nSlices;i++) {
		setSlice(i+1);
//		getHistogram(h_valuesA, h_countsA, 256);
		getStatistics(area, mean, min, max, std, histogramA);	
		colocalized_dots += histogramA[255];
	}

	op = "red='"+Rtitle+"' green='"+Gtitle+"' blue='"+ coloc_name+ "' keep";
	run("RGB Merge...", op);
	colocRGBStackID=getImageID();
	legend1="source: "+sourcepath+originalRGBstackTitle;
	legend2="G_low="+G_g_lower+ " R_low="+G_r_lower + " COLOC Dots="+colocalized_dots;

	setFont("SansSerif", 10);
	setForegroundColor(255, 255, 255);
	drawString(legend1, 10, 20);
	drawString(legend2, 10, 30);
	
	newRname=""+removeExtention(originalRGBstackTitle,".tif") + "_Rth.tif";
	newGname=""+removeExtention(originalRGBstackTitle,".tif") + "_Gth.tif";
	newRGBname=""+removeExtention(originalRGBstackTitle,".tif") + "_coloc.tif";

	selectWindow(Rtitle);
	fullpath=sourcepath + newRname;
	saveAs("tiff", fullpath);

	selectWindow(Gtitle);
	fullpath=sourcepath + newGname;
	saveAs("tiff", fullpath);

	selectImage(colocRGBStackID);
	fullpath=sourcepath + newRGBname;
	saveAs("tiff", fullpath);
	
	selectImage(colocalizedStackID);
	close();
	
	print("****************************************");
	print(sourcepath+ originalRGBstackTitle);
	print("Threshold Green Channel:"+G_g_lower+"-255")
	print("Threshold Red Channel:"+G_r_lower+"-255")
	print("result images: "+ newRname + ", "+ newGname + ", "+ newRGBname + ", ");
	print("---> Colocalized dots [pixels]: "+colocalized_dots);

}

//070822
macro "Measure Dots (G) Colocalized with Muscle signal (R) [f5]" {
	originalRGBstackTitle=getTitle();
	orginalRGBID = getImageID();
	run("RGB Split");
	
	Rtitle=originalRGBstackTitle+" (red)";
	Gtitle=originalRGBstackTitle+" (green)";
	Btitle=originalRGBstackTitle+" (blue)";

	selectWindow(Rtitle);
	RchID = getImageID();
	setThreshold(G_r_lower,255);
	run("Convert to Mask", "stack");

	selectWindow(Gtitle);
	if (Gsizefilterswitch) {
		GchID = DotSizeScreening();
		Gtitle=getTitle();
	} else {
		GchID = getImageID();
		setThreshold(G_g_lower,255);
		run("Convert to Mask", "stack");
	}
	selectWindow(Btitle);
	close();

	imageCalculator("AND create stack", Rtitle,Gtitle);
	colocalizedStackID=getImageID();
	coloc_name=getTitle();
	colocalized_dots=0;	
	for(i=0; i<nSlices;i++) {
		setSlice(i+1);
//		getHistogram(h_valuesA, h_countsA, 256);
		getStatistics(area, mean, min, max, std, histogramA);	
		colocalized_dots += histogramA[255];
	}

	op = "red='"+Rtitle+"' green='"+Gtitle+"' blue='"+ coloc_name+ "' keep";
	run("RGB Merge...", op);
	colocRGBStackID=getImageID();
/*
	legend1="source: "+sourcepath+originalRGBstackTitle;
	legend2="G_low="+G_g_lower+ " R_low="+G_r_lower + " COLOC Dots="+colocalized_dots;

	setFont("SansSerif", 10);
	setForegroundColor(255, 255, 255);
	drawString(legend1, 10, 20);
	drawString(legend2, 10, 30);
	
	newRname=""+removeExtention(originalRGBstackTitle,".tif") + "_Rth.tif";
	newGname=""+removeExtention(originalRGBstackTitle,".tif") + "_Gth.tif";
	newRGBname=""+removeExtention(originalRGBstackTitle,".tif") + "_coloc.tif";

	selectWindow(Rtitle);
	fullpath=sourcepath + newRname;
	saveAs("tiff", fullpath);

	selectWindow(Gtitle);
	fullpath=sourcepath + newGname;
	saveAs("tiff", fullpath);

	selectImage(colocRGBStackID);
	fullpath=sourcepath + newRGBname;
	saveAs("tiff", fullpath);
	
	selectImage(colocalizedStackID);
	close();
*/	
	print("****************************************");
//	print(sourcepath+ originalRGBstackTitle);
	print("Threshold Green Channel:"+G_g_lower+"-255");
	print("Threshold Red Channel:"+G_r_lower+"-255");
//	print("result images: "+ newRname + ", "+ newGname + ", "+ newRGBname + ", ");
	print("---> Colocalized dots [pixels]: "+colocalized_dots);

}

function DotSizeScreening() {
	setThreshold(G_g_lower,255);
	run("Convert to Mask", "stack");
	op = "size="+Gsizemin+"-"+Gsizemax+" circularity=0.50-1.00 show=Masks display clear include stack";
	run("Analyze Particles...", op);
	return getImageID();
}

macro "-"{}

//threshold and clear outside
macro "Clear Background each Slice"{
	//getThreshold(lower,upper);
	lower=getNumber("Lower", G_lower);
	G_lower=lower;
	ClearBackStack(G_lower,255);
}

function ClearBackStack(lower,upper) {
	run("Colors...", "foreground=white background=black selection=yellow");
	for (i=0;i<nSlices;i++) {
		setSlice(i+1);
		setThreshold(lower,upper);
		run("Create Selection");
		run("Clear Outside", "slice");
		run("Select None");
		resetThreshold();
	}

}

//-------------- LIB
//070222 Kota: removes file name extention such as ".tif" and return the 
// prefix. "extensiton" will be removed.
function removeExtention(fullfilename,extensiton) {
	substr2=extensiton;	//".";
	//print(fullfilename);
	Dotindex=indexOf(fullfilename,substr2);	
	pref1start=0;
	pref1end=Dotindex;
	pref1=substring(fullfilename,pref1start,pref1end);
	return pref1;
}

