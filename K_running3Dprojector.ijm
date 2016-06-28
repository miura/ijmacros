/* K_running3Dprojector.ijm

Kota Miura (miura at embl dot de) +49 6221 378404

080827 on request from Annette Schmidt
080828 dialogue added	 

processes 4D sequence, and resulting stack contains time-wise shifting in the 3D-pojection axis. 

The program asks you select
	projecion method
	rotation angle
	to do interpolation or not.
and to input:
 	time points: number of time points in the stack. 
	Angle Increments: The shift in the 3D projection angle in every time step.
	Slice Spacing: expected spacing between slices (in pixels).
	Returning Angle: since the rotation reverses at a certain threshold angle, you must input the maximum angle.

	
*/


var	Gprojmethod;
var	Grotaxis;
var	Gtimepoints = 10;
var	GSliceSpacing = 15;
var	GAngleIncrements = 5;
var	GReturnAngle = 15;
var	GcheckInterpolate = "true";

macro "running 3D projector"{
	UserDialog();
	timepoints = Gtimepoints;	//= getNumber("time points?",10);
	zslices = nSlices/timepoints;
	angleincrements = GAngleIncrements;	//getNumber("angle increment?",5);
	spacing = GSliceSpacing;	//getNumber("slice spacing?", 15);
	returnangle = GReturnAngle;	//getNumber("returning angle ?", 30);
	orgstackID = getImageID();
	ww = getWidth();
	hh = getHeight();
	newImage("resultprojection", "8-bit Black", ww, hh, timepoints);	
	deststackID = getImageID();
	setBatchMode(true);
	currentangle = 0;
	for (j=0; j<timepoints; j++) {	//timepoints
		selectImage(orgstackID );
		run("Duplicate...", "title=NucleusCrop-1.tif duplicate");
		op2 = "first="+((j+1)*zslices+1)+" last="+(timepoints*zslices)+" increment=1";
		run("Slice Remover", op2);
		if (j>0) {
			op1="first="+1+" last="+(j*zslices)+" increment=1";
			run("Slice Remover", op1);
		}
		singletimepointStackID = getImageID();
		if (j!=0) {
			if ((currentangle > returnangle ) || (currentangle < 0) ) angleincrements *=-1;
			currentangle += angleincrements ;	//angle
		}
		print("timepoint"+j+"Projection Angle="+currentangle);	
		//print("slices:"+nSlices);
		op = "projection=["+Gprojmethod+"] axis="+Grotaxis+" slice="+spacing+" initial="+currentangle+" total=0 rotation=10 lower=1 upper=255 opacity=0 surface=100 interior=50"; 
		if (GcheckInterpolate)	op=op+" interpolate";
		run("3D Project...", op);
		run("Copy");
		close();
		selectImage(deststackID);
		setSlice(j+1);
		run("Paste");
		selectImage(singletimepointStackID);
		close();		
	}
	setBatchMode("exit and display");

}


function UserDialog() {
	//choicenum=3;
	//imgIDA=newArray(imgnum);
	projmethodA=newArray("Brightest Point", "Nearest Point", "Mean Value");
	axisA=newArray("X-Axis", "Y-Axis", "Z-Axis");

 	Dialog.create("Running 3D projector");
	Dialog.addChoice("Projection Method", projmethodA);
	Dialog.addChoice("Rotation Axis", axisA);
	Dialog.addNumber("Time Points:", Gtimepoints );
 	Dialog.addNumber("Slice Spacing (pixels):", GSliceSpacing );
 	Dialog.addNumber("Angle Increments:", GAngleIncrements );
 	Dialog.addNumber("Return Angle:", GReturnAngle);
	Dialog.addCheckbox("Interpolate", GcheckInterpolate);
 	Dialog.show();
	Gprojmethod = Dialog.getChoice();
	Grotaxis = Dialog.getChoice();
	Gtimepoints = Dialog.getNumber();
 	GSliceSpacing = Dialog.getNumber();
 	GAngleIncrements = Dialog.getNumber();
 	GReturnAngle = Dialog.getNumber();
	GcheckInterpolate = Dialog.getCheckbox();

	print("**********************************************");
 	print("Projection Method: "+Gprojmethod + " Rotation Axis:"+ Grotaxis); 
	if (GcheckInterpolate ) {
		print("interpolate ON");
	} else {
		print("interpolate OFF");
	}	
}


