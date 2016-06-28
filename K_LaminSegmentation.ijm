//090303 Gauss blur for finding threshold value, and Gauss blur for actual segmentaiton
// after segmentation, hole is filled and then eroded

/*
090724	planned feature: nucleus shape checker. Reslice, check if it is OK. Fit elipse and check the long.short axis distances. 

*/
/*
	gausssigma1=37;	//new strategy
	gausssigma2=1;
*/
function KotasSegmentationEval2para(gausssigma1, gausssigma2) {
	run("Duplicate...", "title=DupOriginalFrame.tif");	//in 090723
	currentID = getImageID();
	currentTitle = getTitle();
	run("Duplicate...", "title=[tempforThresholding]"); // for evaluation
	op ="number=20 smoothings=1 keep=20 a1=0.50 a2=0.90 dt=40 edge=5";
	run("Anisotropic Diffusion 2D", op); 	
	op = "sigma="+gausssigma1;
	run("Gaussian Blur...", op);
	run("MultiThresholder", "Otsu");
	getThreshold(lower, upper);
	//resetThreshold();
	//duplicateID = getImageID();
	close();
	print("Otsu Lower Upper = "+lower+"-"+upper);

	selectImage(currentID);
	run("Duplicate...", "title=[tempforThresholding2]"); // for evaluation 	
	duplicateTitle = getTitle();	//in 090723

	selectImage(currentID);
	op = "sigma="+gausssigma2;
	run("Gaussian Blur...", op);
	setThreshold(upper, 255);
	run("Convert to Mask", "  black");
	run("Fill Holes");	//out 090723
	//for(i=0; i<gausssigma2; i++) run("Erode");
	for(i=0; i<2; i++) run("Erode");
	//for(i=0; i<2; i++) run("Dilate");
	for(i=0; i<1; i++) run("Dilate");

	//op = "red="+duplicateTitle  +" green=*None* blue="+currentTitle+" gray=*None* create keep";
	//op = "red="+duplicateTitle  +" green=*None* blue="+currentTitle+" gray=*None* keep";
	op = "red="+duplicateTitle  +" green=*None* blue="+currentTitle+" gray=*None*";
	run("Merge Channels...", op);
	return upper;
	
}

macro "test lamin segmentation" {
	gausssigma1 = 5;//15;//37;
	gausssigma2 = 0;

	KotasSegmentationEval2para(gausssigma1, gausssigma2);

}

macro "reslice [F1]" {
run("Reslice [/]...", "slice=0.225 slice_count=1");
}
