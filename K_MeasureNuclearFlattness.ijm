

//need binary segmented ucleus. 
function MeasureNuclearFlattness(XZYZsavepath, nucnumber){
	BR2D = MeasureCircularity3D();
	newname="XZYZ"+nucnumber+".tif";
	rename(newname);
	if (lengthOf(XZYZsavepath)>1) saveAs("tiff", (XZYZsavepath+"\\"+newname);
	close();
	return BR2D;
}

macro "dev. measure DAPI crosssection shape"{
	MeasureCircularity3D();
}

function MeasureCircularity3D(){
	orgstackID=getImageID();

	run("Clear Results");

	xzID = prepareXZ();

	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("RenyiEntropy dark");

	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Set Measurements...", "area bounding fit shape limit redirect=None decimal=3");
	run("Analyze Particles...", "size=500-Infinity pixel circularity=0.00-1.00 show=Nothing display include");
	if (nResults>0){
		BX = getResult("BX", 0);
		BY = getResult("BY", 0);
		BoundRecRatioXZ = BX/BY;
		print("XZ boundrec ratio="+BoundRecRatioXZ);
		ARXZ = getResult("AR", 0); //aspect ratio
		print(ARXZ);		
	}


	selectImage(orgstackID);
	run("Clear Results");
	yzID = prepareYZ();
	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("RenyiEntropy dark");

	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Set Measurements...", "area bounding fit shape limit redirect=None decimal=3");
	run("Analyze Particles...", "size=500-Infinity pixel circularity=0.00-1.00 show=Nothing display include");
	if (nResults>0){
		BX = getResult("BX", 0);
		BY = getResult("BY", 0);
		BoundRecRatioYZ = BX/BY;
		print("YZ boundrec ratio="+BoundRecRatioYZ);
		ARYZ = getResult("AR", 0); //aspect ratio
		print(ARYZ);
		BR2D=BoundRecRatioXZ+BoundRecRatioYZ;
		AR2D=(ARXZ+ARYZ);
		print("AR2D="+AR2D+"\tBoundRectangleRaito = "+BR2D);
	} else {
		print("measurment failed");
		BR2D=-1;
	}

	selectImage(yzID);
	yzwidth=getWidth();
	yzheight=getHeight();

	selectImage(xzID);
	xzwidth =getWidth();
	xzheight =getHeight();
	op="width="+(xzwidth+yzwidth)+" height="+xzheight+" position=Center-Left zero";
	run("Canvas Size...", op);

	selectImage(yzID);
	run("Select All");
	run("Copy");

	selectImage(xzID);
	makeRectangle(xzwidth, 0, yzwidth, yzheight);
	run("Paste");

	selectImage(yzID); close();	
	return BR2D;
}



function prepareXZ(){
	setBatchMode(true);		
	run("Reslice [/]...", "slice=0.245 start=Top");
	reslicestackID=getImageID();
	run("Z Project...", "start=1 stop=36 projection=[Max Intensity]");
	XZid=getImageID();
	selectImage(reslicestackID);
	close();
	setBatchMode("exit and display");	
	return XZid;
}

function prepareYZ(){
	setBatchMode(true);			
	run("Reslice [/]...", "slice=0.245 start=Left");
	reslicestackID=getImageID();
	run("Z Project...", "start=1 stop=36 projection=[Max Intensity]");
	YZid=getImageID();
	selectImage(reslicestackID);
	close();
	setBatchMode("exit and display");	
	return YZid;
}
