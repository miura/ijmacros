//Sarada@Knop lab
/* for ratiometry of yeast spots
Kota Miura (miura@mebl.de) CMCI, EMBL

20100614	"first around" error fixed
		added analyze particle minimum size to dialog
20100615  addtional macro for finding out the position of specific dot. 
*/

var Gtitle ="GFP";	//ch0
var G_GID = 0;
var Rtitle = "Cherry";	//ch1
var G_RID = 1;
var Gminarea = 500;
//
var GcreateOriginals = false// 100701

macro "Get Ratio (Sarada)  [f1]" {
	requires("1.44b");	//overlay funciton for particle analysis
	twoImageChoice();
	setBatchMode(true);

	selectWindow(Gtitle);	//ch0
	G_GID = getImageID();
	selectWindow(Rtitle);	//ch1
	G_RID = getImageID();

	selectImage(G_GID);
	preProcessImage();
	backid = BackSubtract(G_GID);	//backID is backgorund ID
	selectImage(backid);
	close();
	mskID = maskBackground(G_GID);

	selectImage(G_RID);
	preProcessImage();
	backid = BackSubtract(G_RID);
	selectImage(backid);
	close();
	imageCalculator("Multiply", G_RID, mskID);
	selectImage(mskID); close();
	
	imageCalculator("Divide create 32-bit", G_RID,G_GID);
	InfTo0();
	resID = getImageID();
	//setBatchMode("exit and display"); 	

	selectImage(resID);
	getStatistics(area, mean, min, max, std);
	print("intensity min="+min+" max="+max);
	setThreshold(min, max+1);
	op = "area mean min centroid stack limit redirect=None decimal=4";
	run("Set Measurements...", op);
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	op = "size="+Gminarea+"-Infinity circularity=0.00-1.00 show=[Overlay Outlines] display exclude clear include";
	run("Analyze Particles...", op);
	resetThreshold();
	setBatchMode("exit and display"); 	
	visRatio();
	if (GcreateOriginals) {
		 visRatio2(G_GID);
		 visRatio2(G_RID);
	}
}


macro "Select Specific Dot [F2]"{
	if (nResults ==0) exit("You should have values in Results window");
	dotID = getNumber("which dot?", 1);
	dotx = getResult("X",dotID-1);
	doty = getResult("Y",dotID-1);
	makePoint(dotx, doty);
}


// just to see spots in color. This uses results table, so above macro should be done first. 

macro "Visualize Ratio (depricated)"{
	visRatio();
}

function visRatio(){
	rmin =1000000;
	rmax =0;
	if (nResults > 1) {
		for (i=0; i<nResults;i++){
			if(getResult("Mean", i)>rmax) rmax = getResult("Mean", i);
			if(getResult("Mean", i)<rmin) rmin = getResult("Mean", i);
		}
	} else {
		getStatistics(area, mean, min, max, std);
		rmax = max;
		rmin = min;
		rmax /=10;
	}
	print("ratio max ="+rmax);
	op = "title=RatioVisualized";
	run("Duplicate...", op);
	roiManager("Show None");
	run("Remove Overlay");
	op = "value="+255/rmax;
	run("Multiply...", op);
	run("Conversions...", " ");
	run("8-bit");
	run("Fire");
	addColorScale(0, rmax);
}

//toapplytoOriginal-Preprocessed Images
//100701
function visRatio2(imgID){
	selectImage(imgID);
	run("Select None");
	rmin =1000000;
	rmax =0;
		getStatistics(area, mean, min, max, std, hist);
		rmax = max;
		rmin = min;
		//rmax /=10;
	print("intensity min ="+rmin);
	print("intensity max ="+rmax);
	currentTitle = getTitle();
	op = "title=[RGB_" + currentTitle+"]";
	run("Duplicate...", op);
	roiManager("Show None");
	run("Remove Overlay");
	op = "value="+255/rmax;
	run("Multiply...", op);
	run("Conversions...", " ");
	run("8-bit");
	run("Fire");
	addColorScale(rmin, rmax);
}

//add color scale in right side, 10pix width 256 height

function addColorScale(smin, smax){
	sw = 30; //scale width
	hfactor = 3;
	topleftx = getWidth() -sw - 20;
	toplefty = getHeight()/2 - 256*hfactor/2;
	for (i=0; i<256; i++){
		for (k=0; k<hfactor; k++){
			for (j=0; j<sw; j++){
				setPixel(j + topleftx , i*hfactor+k+toplefty , 255-i);
			}
		}
	}
	smaxs = ""+smax;
	if ((smax <10000) && (lengthOf(smaxs)>4)) smaxs = substring(smaxs,0,4);
	smids = "" +  smax/2;
	smid = smax/2;
	if ((smid <10000) && (lengthOf(smids)>4)) smids =  substring(smids,0,4);
	smins = "" +  smin;
	if (lengthOf(smins)>4) smids =  substring(smins,0,4);

	//add values to scale
	setColor(255, 255, 255);
	setFont("SansSerif", 36);
  	setJustification("right");
	drawString(smaxs , topleftx - 40, toplefty);
	drawString(smids, topleftx - 40, toplefty + 256*hfactor/2);	 
	drawString(smins, topleftx - 40, toplefty + 256*hfactor);	 
}

/*
macro "-"{}

macro "test background masking"{
	maskBackground(getImageID());
}
*/

//only for GFP channel
function maskBackground(imgID){
	setAutoThreshold("Yen dark");
	run("Analyze Particles...", "size="+Gminarea+"-Infinity circularity=0.10-1.00 show=Masks display exclude clear include add");
	run("Invert LUT");
	mskID = getImageID();
	run("Invert LUT");
	//for (i=0; i<30; i++) run("Erode"); //to eliminate shift
	run("Divide...", "value=255");
	imageCalculator("Multiply", imgID, mskID);
	roicount = roiManager("count");
	roiManager("Combine");
	roiManager("reset");
	roiManager("add")
	return mskID;
}

/*
macro "test nan convert"{
	NanTo0();
}
*/
function NanTo0(){
	hh = getHeight();
	for(i=0; i<hh; i++){
		for(j=0; j<getHeight(); j++){
			cp = getPixel(j, i);
			if (isNaN(cp)) setPixel(j, i, 0);
			if (cp > 100) setPixel(j, i, 0);				
		}
		showProgress(i/hh);
	}
}

function InfTo0(){
	hh = getHeight();
	for(i=0; i<hh; i++){
		for(j=0; j<getWidth(); j++){
			cp = getPixel(j, i);
			if (cp > 100) setPixel(j, i, 0);	
		}
		showProgress(i/hh);
	}
}


function BackSubtract(imgID){
	selectImage(imgID);
	run("Duplicate...", "title=["+getTitle()+"]");
	run("Gaussian Blur...", "sigma=300");
	backID = getImageID();
	imageCalculator("Subtract", imgID,backID);
	return backID;
}

function preProcessImage(){
/*
	run("32-bit");
	run("Subtract...", "value=65535");
	run("Abs");
	run("16-bit");
	run("Invert LUT");
*/
	run("Invert");
	run("Invert LUT");
}

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
 	Dialog.addChoice("GFP channel", wintitleA);
	Dialog.addChoice("Cherry channel", wintitleA);
	Dialog.addNumber("Expected Minimum area (in pixels):", Gminarea); 
	Dialog.addCheckbox("Create Preprocessed Originals", GcreateOriginals); 
	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//;
	Gtitle = Dialog.getChoice();
 	Rtitle = Dialog.getChoice();
	Gminarea= Dialog.getNumber();
	GcreateOriginals = Dialog.getCheckbox();
	print("GFP:"+Gtitle);
	print("Cherry" + Rtitle);
	print("Minimum Area cutoff" + Gminarea);

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
