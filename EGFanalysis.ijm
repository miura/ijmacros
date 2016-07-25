//*** EGFR accumulation measurements:***
//
//Kota Miura (miura@embl.de) started: 060808
// analysis algorithm proposed by Carsten Schulz @ embl.
// process: get profile of a line ROI, get first-order derivative with different dx.
// "Sigma-Derivative Analysis [F1]" created.

//

var dx=1;
var windowsize=2;	//"windowsize" pixels will be added up, and used for the derivative
var linethickness=10;

var PlotRange_y_max=-5000;
var PlotRange_y_min=5000;
var graphswitch=0;

requires("1.37a");

macro "Sigma-Derivative Analysis [F1]" {
	requires("1.34m");
	PlotRange_y_max=-5000;
	PlotRange_y_min=5000;
	delta_x=dx;
	Window_Size=windowsize;
	Line_Width=linethickness;
	Dialog.create("Sigma Derivative");
	Dialog.addMessage("EGFR analysis: Carsten's algorithm");
		//Dialog.addString("Title:", title);
  		//Dialog.addChoice("Type:", newArray("8-bit", "16-bit", "32-bit", "RGB"));
  	Dialog.addNumber("delta_x:", dx);
	Dialog.addNumber("Window_Size:", windowsize);
	Dialog.addNumber("Line_Width:", linethickness);
	Dialog.addCheckbox("Single_Frame", true);
 	Dialog.show();
 	// title = Dialog.getString();
  	delta_x = Dialog.getNumber();
 	Window_Size = Dialog.getNumber();;
 	Line_Width = Dialog.getNumber();
	//	type = Dialog.getChoice();
 	Single_Frame = Dialog.getCheckbox();
	dx=delta_x;
	windowsize=Window_Size;
	linethickness=Line_Width;
  	if (Single_Frame==true) {
		K_profilederivative();
	} else {
		K_measurestack_deriv() ;
	}
 }


//macro "EGF accumulation analysis Vibor special" {
//	K_profilederivative();
//}

//works with single frame, to optimize the parameters
// line width, windowsize, dx
function K_profilederivative() {

	op="line="+linethickness;
	run("Line Width...", op);
	if (isOpen("Log")) {
		selectWindow("Log");
	run("Close");
  	}
	graphswitch=1; 	//global variable
	K_sigmaderivative();
}

//core of the algorithm
function K_sigmaderivative(){

	lineprofileA=getProfile();	//array
	//---- derivative calculation
	shrunklength=floor(lineprofileA.length/windowsize);
	shrunkprofileA=newArray(shrunklength);
	derivativeA=newArray(shrunklength-dx);

	 for (i=0; i<shrunkprofileA.length; i++) {
		shrunkprofileA[i]=K_Retshurnksmoothing(i, windowsize, lineprofileA);
	}
	for (i=0; i<derivativeA.length; i++) {
		derivativeA[i]=shrunkprofileA[i+1]-shrunkprofileA[i];
	}
	if (graphswitch==1) {
		K_create2Plots(shrunkprofileA,derivativeA);
	}

	sigma_derivative=0;
	for (i=0;i<derivativeA.length;i+=1) {
		sigma_derivative+=abs(derivativeA[i]);
	}

	//Plot.create("derivative", "X", "Value", derivativeA);
	//for (i=0; i<lineprofileA.length; i++)
	//	      print(i+"  "+lineprofileA[i]);
	return sigma_derivative;
}

//macro "Measure Sigma Derivative Stack" {
//	K_measurestack_deriv() ;
//}

function K_measurestack_deriv() {
	if (isOpen("Log")) {
		selectWindow("Log");
		run("Close");
  	}

	framenum=nSlices;
	if (nSlices==1) {
		exit("need a stack");
	}
	getLine(x1, y1, x2, y2, L_lineWidth);
	if (x1==-1) {
		exit("need a line selection");
	}

	op="line="+linethickness;
	run("Line Width...", op);

	stnum=1;
	endnum=nSlices;	//getNumber("End with which frame No.?", framenum);
	stepnum=1;	//getNumber("frame step number?", 1);
	graphswitch=0; 	//global variable
	SigDerivativeA=newArray(endnum-stnum+1);
	for (i=0;i<SigDerivativeA.length;i+=stepnum) {
		setSlice(i+stnum);
		makeLine(x1, y1, x2, y2);
		SigDerivativeA[i]=K_sigmaderivative();
	}
	K_createsigderiPlot(SigDerivativeA);
	for (i=0; i<SigDerivativeA.length; i++)
		      print(i+"  "+SigDerivativeA[i]);
	selectWindow("Log");
	//saveAs("Text", "/Users/wayne/profile.txt");
	saveAs("Text");
}

//******** funcitons ****************
shrink the profile by summing up points defined by windowsize.
function K_Retshurnksmoothing(pointnum, windowsize, srcA) {
	windowsum=0;
	for (j=0; j<windowsize; j++)
		windowsum+=srcA[pointnum*windowsize+j];
	return windowsum;
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

//********* Plotting *******
function K_create2Plots(firstA,sencondA) {
	K_updatePlotRange(firstA);
	//print("min "+PlotRange_y_min+" max "+PlotRange_y_max);
	K_updatePlotRange(sencondA);
	//print("min "+PlotRange_y_min+" max "+PlotRange_y_max);

	Plot.create("Derivative", "X", "Value");
	Plot.setLimits(0, firstA.length-1, PlotRange_y_min, PlotRange_y_max);
	Plot.setColor("black");
	Plot.add("line", firstA);
	Plot.setColor("red");
	Plot.add("line", sencondA);
	op="delta-X: "+dx+"  Window Size: "+windowsize+" Line Width: "+linethickness;
	Plot.addText(op, 0.1, 0);
	Plot.show();
}

function K_createsigderiPlot(sigderiA) {
	K_updatePlotRange(sigderiA);
	Plot.create("Sigma Derivative", "frames", "Sigma Derivative");
	Plot.setLimits(0, sigderiA.length-1, PlotRange_y_min, PlotRange_y_max);
	Plot.setColor("black");
	Plot.add("line", sigderiA);
	Plot.show();
}
