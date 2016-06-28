/*k_knop.ijm
Yeast protein Distribution analysis
Kota Miura / @embl.de

080709- 
for measureing protein integrated density along long axis of budding yeast
Thresholding is used to semi-automatically segment the yeast segment the  

070813 module for manual segmentation (manually drawn polygon ROI is converted to mask)
	-further implementaiton: currently, single pixel 
	position is omitted but this better be different in manual ROI module. 

070819 make further macro, that measures the second channel. 
	- popup menu for selecting channels
	- output is integrated density along the distance from tip position. 
	- planned changes
		- make graph plots specially for this.
		- maybe preferred minimum threshold level, so in many cases one 
			do not need to adjust the level. 
		- highest intensity (nuclear position) in pixels and relative distance.

070820 
	- threshold value preservation
	- marking (not working in 32 bit)
	- dialog for parameter setting
	- manual adjustment of tip/tail positions
070824 Polygon selection also works for single channel measurement to mark the cell. 
070827 ToDo: set forgroundcolorWhite and backgroundBlack for the manual segmentation (F7) --> done 071106
070828 added manual adjustment of the long axis to the manual polygon segmentation. 
	for this, seperated "doMeasurement()" in to two parts. measureCore is now added.
070829 window naming global variable fixed
	a bug with parameter setting fixed
071105 	"setBackgroundColor(0, 0, 0);//071105" in "CropGenerateMask(infA, ch2switch) "	
	changed the offset value for the cropping to 30. 	
*/

var G_originalID = -1;
var G_originalCropID;
var G_subimgID;
var G_maskID;
var G_ch2ID;
var G_1title;	//string
var G_2title;	//string
var G_originalCh2CropID;
var GmaskedorigID; //070827

var PlotRange_y_max=-50000;
var PlotRange_y_min=50000;

var GThresholdMin = 0;
var GThresholdMax = 65536;
var G_gaussradius=35;
var G_windowswitch=1;
var G_origimgtitle="tt.tif";
var G_orgxpos=0;
var G_orgypos=0;
//var G_backaveint=42700;
var G_backaveint=96;
var G_minWidth =1;

var G_widthadjust=0; //070815
var Gtipadustswitch =1;
var Gtailadustswitch =0;

var GtipShrink =0;
var GtailShrink =0;

var GtipX;	//070827
var GtipY;
var GtailX;	//for marking 
var GtailY; 
var GMinorlen;

macro "get & set Backgournd Average Intensity [F1]" {
	getSelectionBounds(Bxpos, Bypos, Bwidth, Bheight);
	if ((Bxpos==0) &&  (Bypos==0)) exit("you need to place a rectangular ROI in the background");
	getStatistics(Barea, Bmean, Bmin, Bmax);
	G_backaveint = Bmean;
	print("------\nBackground set to" + G_backaveint + "\n------");
}

macro "-"{}
/***************
macro "numerically set Gaussian blurr radius" {
	G_gaussradius = getNumber("Gauss Radius?", G_gaussradius);
}

macro "numerically set  Backgound Average Intensity" {
	G_backaveint = getNumber("background mean intensity?", G_backaveint);
}

macro "numerically set Width tolerance" {
	G_minWidth = getNumber("tolerance of yeast width?", G_minWidth);
}
*****************/
macro "Set Parameters [F2]" {
	 setpara070820();
}

macro "Force-shrink the Line ROI [F3]" {
	 setShrink070820();
}

function setpara070820() {

 	Dialog.create("Set Parameters");
	Dialog.addMessage("Background ave. intensity can be set easier by\n 'get & set Backgournd Average Intensity'.");
	Dialog.addNumber("background average intensity", G_backaveint);
	Dialog.addMessage("A larger gauss radius enables preservation of smaller structures.");
	Dialog.addNumber("Gauss Blur Radius for Preprocessing",  G_gaussradius);
	Dialog.addMessage("minimum width of the cross section that will be considered as tip or tail. \n Check the box below to activate.");
	Dialog.addNumber("Minimum Width at the tip or end",  G_minWidth);
	Dialog.addCheckbox("...auto - adjust tip", Gtipadustswitch);
	Dialog.addCheckbox("...auto - adjust end", Gtailadustswitch);

 	Dialog.show();
	G_backaveint = Dialog.getNumber();
	G_gaussradius = Dialog.getNumber();
	G_minWidth = Dialog.getNumber();
	Gtipadustswitch=Dialog.getCheckbox();
	Gtailadustswitch=Dialog.getCheckbox();
}

function setShrink070820() {

 	Dialog.create("Set Shrink");
	Dialog.addMessage("Setting these values will force-shrink\nthe line ROI in each side \nthat was automatically set by the program.");
	Dialog.addNumber("Tip Shrink by", GtipShrink );
	Dialog.addNumber("Tail Shrink by", GtailShrink );
 	Dialog.show();
	GtipShrink =Dialog.getNumber();
	GtailShrink =Dialog.getNumber();
}

macro "-"{}

macro "See all images" {
	G_windowswitch = 0;
}

macro "See only part of images" {
	G_windowswitch = 1;
}


macro "-"{}

macro "yeast preprocessing 1ch [F5]" {
	yeastPreprocess(0);
}

macro "... Measure distribution by threshold [F6]" {
	infA = newArray(7);
	thresholdsegment(infA);
	doMeasurements(infA, 0);
	MeasurementCore(GMinorlen, GtipX, GtipY, GtailX, GtailY, 0);
}

macro"Measure distribution using manual Polygon ROI [F7]"{
	infA = newArray(7);
	CropGenerateMask(infA, 0);
	doMeasurements(infA, 0);
	MeasurementCore(GMinorlen, GtipX, GtipY, GtailX, GtailY, 0);
}

macro"... with Manual adjustment of the Long Axis [F8]"{
	infA = newArray(7);
	CropGenerateMask(infA, 0);
	doMeasurements(infA, 0);
}
macro "............continue [F9]" {
	getManuallyCorrectedLine();
	MeasurementCore(GMinorlen, GtipX, GtipY, GtailX, GtailY, 0);
}


macro "-"{}

macro "yeast preprocessing 2ch (measure DAPI) [F10]" {
	yeastPreprocess(1);
}


macro "...measure by threshold 2ch [F11]" {
	infA = newArray(7);
	thresholdsegment(infA);
	doMeasurements(infA, 1);
	MeasurementCore(GMinorlen, GtipX, GtipY, GtailX, GtailY, 1);
}

macro "-" {}

macro "Mark the Analyzed Cell [F12]" {
	selectImage(G_originalID);
	setColor(255, 255, 255);
	setFont("SansSerif", 12);
	drawString("*", G_orgxpos + GtailX, G_orgypos + GtailY);
}


////////////////////////////////////////////////////////////////////////////////////////////

//070827
function getManuallyCorrectedLine() {
	getLine(x1, y1, x2, y2, lineWidth);
	if ((x1==-1) || (selectionType()!=5)) exit("No Straight Line selection made: redo");
	if (getImageID() != G_originalCropID) exit("Line selection must be in the 'cropped32bit' window");
	GtipX = x1;	//070827
	GtipY = y1;
	GtailX = x2 ;	//for marking 
	GtailY = y2; 
	print("Tip-Tail axis manually adjusted");
	print(">>Tip: " + GtipX + "," + GtipY);
	print(">>Tail: " + GtailX + "," + GtailY);
	print(">>calculated length: " + sqsumrt(GtipX ,GtipY,GtailX, GtailY) +"pixels");
}


function yeastPreprocess(ch2switch){
	getSelectionBounds(G_orgxpos, G_orgypos, width, height);
	if ((G_orgxpos==0) &&  (G_orgypos==0)) exit("you need to place a rectangular ROI containing yeast");
	G_originalID = getImageID();
	if (ch2switch) {
		twoChChoice070816();
		selectImage(G_2title);
		makeRectangle(G_orgxpos, G_orgypos, width, height);
		run("Duplicate...", "title=ch2_cropped16bit.tif");
		G_originalCh2CropID = getImageID();
		selectImage(G_1title);		
	}
	setBatchMode(true);
	G_origimgtitle = getTitle();
	run("Duplicate...", "title=cropped.tif]");
	G_originalCropID=getImageID();
	run("Duplicate...", "title=cropped16bit.tif");
	img16bitID = getImageID();
	run("16-bit");
	run("Duplicate...", "title=cropped16bitblur.tif");
	img16bitblurID = getImageID();
	op = "radius="+G_gaussradius;
	run("Gaussian Blur...", op);
	imageCalculator("Subtract", img16bitID ,img16bitblurID);
	selectImage(img16bitblurID);
	if (G_windowswitch) close();
	selectImage(img16bitID );	
	G_subimgID=getImageID();
	if (GThresholdMin>0) {
		setThreshold(GThresholdMin, GThresholdMax);
	} else {
		setAutoThreshold();	
	}
	setBatchMode("exit and display");

}

function twoChChoice070816() {
	imgnum=Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("Select Images");
	Dialog.addChoice("Ch1 (for contour detection)", wintitleA);
	Dialog.addChoice("Ch2 (for measurement)", wintitleA);
/*
	Dialog.addNumber("Line Width for Measurement", G_width);
	Dialog.addCheckbox("Measure MT tip position",G_MeasureMapSwitch);
*/

 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 
 	G_1title = Dialog.getChoice();
	G_2title = Dialog.getChoice();

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


//thresholded image.
function thresholdsegment(infA) {
	//subimgID=getImageID();
	selectImage(G_subimgID);
	getThreshold(GThresholdMin, GThresholdMax);
	run("Set Scale...", "distance=1 known=1 pixel=1 unit=pixels global");
	run("Set Measurements...", 
		"area centroid center fit integrated redirect=None decimal=2");
	run("Analyze Particles...", 
		"size=500-Infinity circularity=0.1 -1.00 show=Masks display clear include summarize");
	G_maskID=getImageID();	
	if (nResults() != 1) exit("Abort: Redo Thresholding");
	//areameasured = getResult("Area", 0);
	centroidX = getResult("X", 0);
	centroidY = getResult("Y", 0);
	centmassX = getResult("XM", 0);
	centmassY = getResult("YM", 0);
	Majorlen =  getResult("Major", 0);
	Minorlen =  getResult("Minor", 0);
	IntegratedDens = getResult("IntDen", 0);
	//infA = newArray(centroidX, centroidY, centmassX, 
	//	centmassY, Majorlen, Minorlen, IntegratedDens);
	infA[0] = centroidX;
	infA[1] = centroidY;
	infA[2] = centmassX;
	infA[3] = centmassY;
	infA[4] = Majorlen;
	infA[5] = Minorlen;
	infA[6] = IntegratedDens;

	selectImage(G_subimgID);
	if (G_windowswitch) close();
	selectImage(G_maskID);
	run("Open");
}


function SetScaleSefault() {
	run("Set Scale...", "distance=1 known=0 pixel=1 unit=pixels global");
}

function CropGenerateMask(infA, ch2switch) {
	SetScaleSefault();
	offsetwidth=35;
	stype=selectionType();
	if ((stype!=2) && (stype!=3)) exit("polygon ROI or freehand ROI must be drawn");
	G_originalID = getImageID();
	G_origimgtitle = getTitle();
	getSelectionCoordinates(roixA, roiyA);
	getSelectionBounds(rightx, topy, width, height);
	cropx=rightx-offsetwidth;
	cropy=topy-offsetwidth;
	cropw=width+2*offsetwidth;
	croph=height+2*offsetwidth;
	G_orgxpos = cropx;
	G_orgypos = cropy;
	if (ch2switch) {
		twoChChoice070816();
		selectImage(G_2title);
		if (G_1title != G_origimgtitle) exit("You selected wrong image...");
		makeRectangle(cropx, cropy, cropw, croph);
		run("Duplicate...", "title=ch2_cropped16bit.tif");
		G_originalCh2CropID = getImageID();
		selectImage(G_1title);		
	}
	makeRectangle(cropx, cropy, cropw, croph);
	run("Duplicate...", "title=cropped32bit.tif");
	G_originalCropID=getImageID();
	SetScaleSefault();

	for(i=0; i<roixA.length; i++){
		roixA[i] -= cropx;
		roiyA[i] -= cropy;
	} 
	makeSelection(stype, roixA, roiyA);
	SetScaleSefault();
	run("Set Measurements...", 
		"area centroid center fit integrated redirect=None decimal=2");
	run("Clear Results");
	run("Measure");
	if (nResults() != 1) exit("Abort: Redo ROI");
	//areameasured = getResult("Area", 0);
	centroidX = getResult("X", 0);
	centroidY = getResult("Y", 0);
	centmassX = getResult("XM", 0);
	centmassY = getResult("YM", 0);
	Majorlen =  getResult("Major", 0);
	Minorlen =  getResult("Minor", 0);
	IntegratedDens = getResult("IntDen", 0);

	infA[0] = centroidX;
	infA[1] = centroidY;
	infA[2] = centmassX;
	infA[3] = centmassY;
	infA[4] = Majorlen;
	infA[5] = Minorlen;
	infA[6] = IntegratedDens;
	
	selectImage(G_originalCropID);
	run("Select None");	
	run("Duplicate...", "title=mask8bit.tif");	
	G_maskID=getImageID();
	SetScaleSefault();
	makeSelection(stype, roixA, roiyA);
	run("8-bit");
	setForegroundColor(255, 255, 255);
	run("Fill");
	setBackgroundColor(0, 0, 0);//071105
	run("Clear Outside");
}

function doMeasurements(infA,ch2switch){
	centroidX =	 	infA[0];
	centroidY = 		infA[1];
	centmassX = 		infA[2];
	centmassY = 		infA[3];
	Majorlen =  		infA[4];
	Minorlen =  		infA[5];
	IntegratedDens =	infA[6];

	selectImage(G_maskID);
	if (getPixel(centroidX , centroidY ) !=255) exit("This yeast has abnormal shape. Forget about this guy.");
	paraA=newArray(2);
	if (centroidY != centmassY ) {
		vertical = 0;
		calcLinEq(centroidX ,centroidY , centmassX , centmassY , paraA);
	} else {
		vertical = 1;
	}
	print(paraA[0] + "," +paraA[1]);
 
	// decreasing
	currentX = round(centroidX);
	currentY = round(centroidY);
	currentInt = 255;
	if (vertical ==0) {
		while (currentInt ==255) {
			currentX -=1 ;
			currentY = paraA[0] * currentX + paraA[1];
			currentInt = getPixel(currentX , round(currentY)); 		
		}
		leftX = currentX+G_widthadjust;
		leftY = currentY+G_widthadjust;
		print("leftX:"+leftX +"leftY"+leftY );
	
		// increasing
		currentX = centroidX;
		currentY = centroidY;
		currentInt = 255;
		while (currentInt ==255) {
			currentX +=1 ;
			currentY = paraA[0] * currentX + paraA[1];
			currentInt = getPixel(currentX , currentY); 		
		}
		rightX = currentX-G_widthadjust;
		rightY = currentY-G_widthadjust;
	} else {
		while (currentInt ==255) {
			currentY  -=1;
			currentInt = getPixel(currentX , currentY); 		
		}
		leftX = currentX;
		leftY = currentX+1;
		while (currentInt ==255) {
			currentY  +=1;
			currentInt = getPixel(currentX , currentY); 		
		}
		rightX = currentX;
		rightY = currentX-1;
	}

// Determine where the tip is

	distance_left_centroid = sqsumrt(leftX, leftY, centroidX, centroidY);
	distance_left_centmass = sqsumrt(leftX, leftY, centmassX , centmassY );
	
	if (distance_left_centroid > distance_left_centmass) {
		tipX = leftX;
		tipY = leftY;
		tailX = rightX;
		tailY = rightY;
	} else {
		tipX = rightX;
		tipY = rightY;
		tailX =leftX ;
		tailY =leftY ;
	}

// MEASUREMENT of Width by MASK, readjustment of edge
	selectImage(G_maskID);
	run("Line Width...", "line=1");
	makeLine(tipX, tipY, tailX, tailY);
  // Get 
	getSelectionCoordinates(xCA, yCA);
	for(i=0; i<xCA.length; i++) print (xCA[i]+","+yCA[i]);
	pointnumA=newArray(xCA.length-1);//070705
	totalprofilelength = returnSegmentROIcountPoints(xCA, yCA, pointnumA);
	xFCA = newArray(totalprofilelength );
	yFCA = newArray(totalprofilelength );
	ConvertSegROItoFreeROI(xCA, yCA, pointnumA, xFCA, yFCA);

	//Plot.create("Test", "X", "y", xFCA, yFCA);
	//Plot.show();
	//selectImage(G_maskID);

	run("Line Width...", "line="+(Minorlen*1.2));
	makeLine(tipX, tipY, tailX, tailY);
	testwidthA = getProfile();
	for(i=0; i<testwidthA .length; i++) {
		testwidthA[i] = round(testwidthA[i] * Minorlen*1.2 /255);		//width at that position
	}
	//Plot.create("Test", "X", "crosssec", testwidthA);
	//Plot.show();
	selectImage(G_maskID);

//check if the edge really contains signal. Width should be greater than G_minWidth.	
	tipoffset=0;
	if (Gtipadustswitch) {
		while(testwidthA[tipoffset]<G_minWidth) tipoffset++;
	}
	tailoffset=testwidthA.length-1;
	if (Gtailadustswitch) {
		while(testwidthA[tailoffset]<G_minWidth) tailoffset--;
	}
	tipoffset += GtipShrink;
	tailoffset -= GtailShrink;
	print("Initial Length:" + testwidthA.length);
	print("tipoffset:"+tipoffset+"  tailoffset:"+tailoffset);

	if ((tipoffset>0) || (tailoffset>0)) {
		tipX = xFCA[tipoffset];
		tipY = yFCA[tipoffset];
		tailX = xFCA[tailoffset];
		tailY = yFCA[tailoffset];
	}
/* 070827 move to the core
	makeLine(tipX, tipY, tailX, tailY);
	widthA = getProfile();	
	for(i=0; i<widthA.length; i++) {
		//widthA[i] = round(widthA[i] * Minorlen /255);		//width at that position
		widthA[i] = (widthA[i] * Minorlen*1.2 /255);		//width at that position
	}
*/

	//Plot.create("Test", "X", "crosssec", widthA);
	//Plot.show();

	selectImage(G_maskID);
	print(">>Tip: " + tipX + "," + tipY);
	print(">>Tail: " + tailX + "," + tailY);
	print(">>calculated length: " + sqsumrt(tipX ,tipY,tailX, tailY) +"pixels");

	GtipX = tipX;
	GtipY = tipY;
	GtailX = tailX;
	GtailY = tailY;

	selectImage(G_originalCropID);
	originalimgbits =bitDepth();

//MASKING the ORIGINAL
	selectImage(G_maskID);
	run("Select None");
	run("Divide...", "value=255");
	op = ""+originalimgbits +"-bit";
	run(op);
	if (ch2switch) {	//ch2 is for DAPI measurements
		imageCalculator("Multiply create 32-bit", G_originalCh2CropID, G_maskID);

	} else {
		imageCalculator("Multiply create 32-bit", G_originalCropID, G_maskID);
	}
	rename("masked32bit");	
	GmaskedorigID=getImageID();
	//run("Enhance Contrast", "saturated=0.5");

	GMinorlen = Minorlen;
	selectImage(G_originalCropID);
	makeLine(tipX, tipY, tailX, tailY);
	for(i=0;i<3;i++) run("In");
	setTool(0);
}

//070827 seperated from above 
//MEASUREMENT of Masked Original Image
// parameters required: Minorlen, tipX, tipY, tailX, tailY, widthA[], ch2switch
function MeasurementCore(Minorlen, tipX, tipY, tailX, tailY, ch2switch) {

	selectImage(G_maskID);
	makeLine(tipX, tipY, tailX, tailY);
	widthA = getProfile();	
	for(i=0; i<widthA.length; i++) {
		//widthA[i] = round(widthA[i] * Minorlen /255);		//width at that position
		widthA[i] = (widthA[i] * Minorlen*1.2 /255);		//width at that position
	}

	selectImage(GmaskedorigID);
	run("Line Width...", "line="+(Minorlen*1.2));
	makeLine(tipX, tipY, tailX, tailY);
	signalA = getProfile();
	if (G_windowswitch) close();

//Calculate Per AREA
	integIntA = newArray(signalA .length);
	intperareaA = newArray(signalA .length);
	absolutedistA=  newArray(signalA .length);
	relativedistA = newArray(signalA .length);

	for(i=0; i<signalA .length; i++) {
		//print(signalA [i]);
		//signalA [i] -= G_backaveint;	//background subtraction
		//signalA [i] = (signalA [i] -G_backaveint)  ;
		//print(signalA [i]);
		if (widthA[i]>0) {	
			//integIntA[i] = signalA [i] * Minorlen /widthA[i] - G_backaveint;		//integrated intensity at that position
			integIntA[i] = signalA [i] * Minorlen*1.2 - G_backaveint *widthA[i];
			//integIntA[i] = (signalA [i]-G_backaveint) * Minorlen*1.2; //use floor???
			intperareaA[i] = integIntA[i] / widthA[i] / 3.1415;	//per area
		}
		absolutedistA[i] = i;
		if (i>0) relativedistA[i] = (i)/signalA .length; //relative distance
	}

//OUTPUT INFO
	output_results5(absolutedistA, relativedistA, widthA, signalA ,integIntA, intperareaA);	
	print("Array Length: "+ signalA .length + "pixels");
	//if (ch2switch) {
	//	selectImage(GmaskedorigID);
	//} else {
		selectImage(G_originalCropID);
	//}
	makeLine(tipX, tipY, tailX, tailY);

	selectImage(G_maskID);
	run("RGB Color");
	run("Line Width...", "line=1");
	makeLine(tipX, tipY, tailX, tailY);
	setForegroundColor(255,0,0);
	run("Draw");	
	run("Line Width...", "line="+(Minorlen*1.2));
	makeLine(tipX, tipY, tailX, tailY);
	setForegroundColor(0,0,255);
	run("Draw");
	setForegroundColor(155,155,155);
	setFont("SansSerif", 10);
	printtext = "Crop: "+G_origimgtitle+"\n(" +G_orgxpos+","+G_orgypos+")\n";
	printtext=printtext+"Tip:("+round(tipX)+","+round(tipY)+") \ntail:("+round(tailX)+","+round(tailY)+")";
	drawString(printtext, 0 , 10);

/*070828	print("Integrated Intensity (measured subtraction image):"+ IntegratedDens);
	totalprofileintensity=0;
	for(i=0; i<integIntA.length; i++) totalprofileintensity += integIntA[i];
	print("Integrated Intensity (plot integration subtracted by Back int):"+totalprofileintensity );
	print("Difference: "+(IntegratedDens-totalprofileintensity));
*/
	run("Select None");
	run("Line Width...", "line=1");
	setForegroundColor(255,255,255);
//Plotting

	if (ch2switch) {
		K_TotalIntensityVsDistancePlot(integIntA, 1);
		K_TotalIntensityVsRelativeDistancePlot(integIntA, relativedistA, 0);

	} else {	
		K_IntensityVsDistancePlot(intperareaA, 1);
		K_IntensityVsRelativeDistancePlot(intperareaA, relativedistA, 0);
	}
}



//
function output_results5(r1A, r2A, r3A, r4A,r5A, r6A) {
	run("Clear Results");
	for(i = 0; i < r1A.length; i++) { 
            	//setResult("n", i, i);
           		setResult("Abs Dist", i, r1A[i]);
           		setResult("Rel Dist", i, r2A[i]);
           		setResult("YeastWidth", i, r3A[i]);
           		setResult("AvgIntensity", i, r4A[i]);
           		setResult("IntgIntensity", i, r5A[i]);
           		setResult("IntgIntPerArea", i, r6A[i]);
	}
	updateResults();
}

// plotting functions Intensity/area

function K_IntensityVsDistancePlot(pA, InteractiveRange_switch) {
       if (InteractiveRange_switch) K_updatePlotRange(pA);
       Plot.create("Intensity Profile Absolute Distance", "distance from Tip [pixels]", "Intensity / surface area");
       Plot.setLimits(0, pA.length, PlotRange_y_min*0.95, PlotRange_y_max*1.05);
       Plot.setColor("black");
       Plot.add("line", pA);
       Plot.show();
}

function K_IntensityVsRelativeDistancePlot(pA, xA, InteractiveRange_switch) {
       if (InteractiveRange_switch) K_updatePlotRange(pA);
       Plot.create("Intensity Profile Relative Distance", "relative distance from Tip", "Intensity / surface area");
       Plot.setLimits(0, 1, PlotRange_y_min*0.95, PlotRange_y_max*1.05);
       Plot.setColor("black");
       Plot.add("line", xA , pA);
       Plot.show();
}

function K_TotalIntensityVsDistancePlot(pA, InteractiveRange_switch) {
       if (InteractiveRange_switch) K_updatePlotRange(pA);
       Plot.create("Intensity Profile Absolute Distance", "distance from Tip [pixels]", "Integrated Intensity");
       Plot.setLimits(0, pA.length, PlotRange_y_min*0.95, PlotRange_y_max*1.05);
       Plot.setColor("black");
       Plot.add("line", pA);
       Plot.show();
}

function K_TotalIntensityVsRelativeDistancePlot(pA, xA, InteractiveRange_switch) {
       if (InteractiveRange_switch) K_updatePlotRange(pA);
       Plot.create("Intensity Profile Relative Distance", "relative distance from Tip", "Integrated Intensity");
       Plot.setLimits(0, 1, PlotRange_y_min*0.95, PlotRange_y_max*1.05);
       Plot.setColor("black");
       Plot.add("line", xA , pA);
       Plot.show();
}



// normalization
//copied from segmentation...ijm
function NormalizeInputOutputArrays(inA, outA) {
	maxval = -1000000000;
	minval = 1000000000;
	for (i=0; i<inA.length; i++) {
		if (inA[i] < minval) minval=inA[i];
		if (inA[i] > maxval) maxval=inA[i];
	} 

	for (i=0; i<inA.length; i++) {
		outA[i] = (inA[i]-minval) / (maxval-minval) ;
	}
	//print(minval + " max " + maxval);
	return  (maxval-minval);
}


//070809 copied from segmentation ...ijm
//070810 added none 0 criteria for minimum
//to set a plot range to fit a curve. global variables are used.
function K_updatePlotRange(referenceA) {
	PlotRange_y_max=-50000;
	PlotRange_y_min=50000;
       for (k=0;k<referenceA.length;k++) {
               if (PlotRange_y_max<referenceA[k])
                       PlotRange_y_max=referenceA[k];
               if ((PlotRange_y_min>referenceA[k]) && (referenceA[k]!=0))
                       PlotRange_y_min=referenceA[k];
       }
}


// math***************
function calcLinEq(x1,y1, x2, y2, paraA) {
	a = (y2-y1)/(x2-x1);
	b = y1 - a*x1;
	paraA[0] = a;
	paraA[1] = b;
}

function sqsumrt(a,b,c,d) {
	sumsq = pow((a-c),2) + pow((b-d),2);
	return pow(sumsq,0.5);
}

//********************** quadratic formula 
// http://en.wikipedia.org/wiki/Quadratic_equation

function quadXplus(a, b, c) {
	return (-1 * b + pow((pow(b, 2) - 4 * a * c),0.5)) / 2 / a;
}

function quadXminus(a, b, c) {
	return (-1 * b - pow((pow(b, 2) - 4 * a * c),0.5) ) / 2 / a;
}

//*************************copied from K_segmentedlinewidthcontrol

//070810 modified
/*
macro "test SegmentedROI to Free ROI" {
	getSelectionCoordinates(xCA, yCA);
	//for(i=0; i<xCA.length; i++) print (xCA[i]+","+yCA[i]);
	pointnumA=newArray(xCA.length-1);//070705
	totalprofilelength = returnSegmentROIcountPoints(xCA, yCA, pointnumA)
	xFCA = newArray(totalprofilelength );
	yFCA = newArray(totalprofilelength );
	ConvertSegROItoFreeROI(xCA, yCA, pointnumA, xFCA, yFCA);
	makeSelection("freeline", xFCA, yFCA);
	//output_results3col(xFCA, yFCA);
}
*/

//070706
//070712 used.
// Converts segmented line ROI to freehand ROI (all points on the line becomes coordinates)
// test for converting point detected in the intensity profile plot to xy coordinate. 
function ConvertSegROItoFreeROI(xCA, yCA, pointnumA, xFCA, yFCA) {
	segresultA=newArray(3);
	destCoordsA=newArray(2);

	for (i=0; i<xFCA.length; i++) {
		SegmentROIcalcRest(xCA, yCA,pointnumA,i, segresultA);
		x1 = xCA[segresultA[0]];
		y1 = yCA[segresultA[0]];
		x2 = xCA[segresultA[0]+1];
		y2 = yCA[segresultA[0]+1];
		if (segresultA[2]==0) {
		//if (i==0) {
			destCoordsA[0] = x1;
			destCoordsA[1] = y1;
		} else {
			if (((sqsumrt(x1,y1, x2, y2)-0.5) < segresultA[2]) &&  (segresultA[2] < (sqsumrt(x1,y1, x2, y2)+0.5))) {
				destCoordsA[0] = x2;
				destCoordsA[1] = y2;
			} else {
				returnXdistancefromPoint1(x1,y1, x2, y2, segresultA[2], destCoordsA);
			}
		}
		//print(x1+","+y1+","+ x2+","+ y2+", rest"+segresultA[2]);
		xFCA[i] = destCoordsA[0];
		yFCA[i] = destCoordsA[1];
		//print (destCoordsA[0]+"," +destCoordsA[1]);
		//print("*************************************************************");
	}	
}

/*
macro "measure segment ROI length by profile" {
	getSelectionCoordinates(xCA, yCA);
	pointnumA=newArray(xCA.length-1);//070705
	returnSegmentROIcountPoints(xCA, yCA, pointnumA);
}
*/
function returnSegmentROIcountPoints(xCA, yCA, pointnumA){
	totalprofilelength =0;
	for (i = 0; i < xCA.length-1; i++) {
		makeLine(xCA[i], yCA[i], xCA[i+1], yCA[i+1]);
		tempProfile=getProfile();
		totalprofilelength += tempProfile.length;
		pointnumA[i]=tempProfile.length;
	}
	subtotal=0;
	for (i=0; i<pointnumA.length; i++)  {
		//print (pointnumA[i]);
		subtotal +=pointnumA[i];
	}
	//print("totalprofilelength:"+totalprofilelength + " Integrated pointnumA:" + subtotal);
	return totalprofilelength;
	
}

function SegmentROIcalcRest(xCA, yCA,pointnumA,distance, segresultA) { 

	totalprofilelength = returnSegmentROIcountPoints(xCA, yCA, pointnumA);
	if (distance>totalprofilelength) exit("segment ROI problem");

	integrateDist = 0;
	i=0;
	if (distance>0) {
		while (integrateDist<distance) {
			integrateDist+=pointnumA[i++];
		}	 
		LastSegmentNumber=i-1;
	} else {
		LastSegmentNumber= i;
	}
	offset=0;
	for(j=0; j<LastSegmentNumber; j++) offset+=pointnumA[j];

	RestPoints = (distance-offset);
	if (RestPoints==pointnumA[LastSegmentNumber]) {
		RestPoints=0;
		LastSegmentNumber+=1;
		offset=0;
		for(j=0; j<LastSegmentNumber; j++) offset+=pointnumA[j];
	}

	segresultA[0] = LastSegmentNumber;
	segresultA[1] = offset;
	segresultA[2] = RestPoints ;

	//print("setting="+distance+"  total Profile="+totalprofilelength);
	//print(LastSegmentNumber+"segment (offset points:"+offset+") + fragment "+RestPoints);

	//for (i=0; i<pointnumA.length; i++) print (pointnumA[i]);
	return (distance-offset);
}

// returns xy coordinates within the line (x1,y1) (x2, y2), with "distance" apart from x1y1.
function returnXdistancefromPoint1(x1,y1, x2, y2, distance, destCoordsA) {
	if (distance==0) {
		destCoordsA[0] = x1; 
		destCoordsA[1] = y1;
	} else {
		slope = (y2-y1)/(x2-x1);
		cross= y1 - x1 * slope;
		//print(x1+","+y1);
		//print(x2+","+y2);
		a = 1 + pow(slope,2);
		b = -2 * (x1 + y1*slope - slope * cross);
		c = pow(x1,2)+ pow(y1,2)+ pow(cross,2)  - 2*y1*cross - pow(distance,2);
		xplus = quadXplus(a, b, c);
		xminus=quadXminus(a, b, c);
		//print(xplus + ":" + xminus );
		if (((xplus>x1) && (xplus<x2)) || ((xplus<x1) && (xplus>x2))) {
			destCoordsA[0] =  xplus;
		} else {
			destCoordsA[0] =  xminus;
		}
		destCoordsA[1] = destCoordsA[0]*slope + cross;
	}
}

