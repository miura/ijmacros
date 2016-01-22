// overlay to ROI, 
// set line width to 1 and drarw track through stack
run("RGB Color");
run("To ROI Manager");
roinum = roiManager("count");
for (i = 0; i < roinum; i++){
	roiManager("Select", i);
	roiManager("Set Line Width", 1);
	run("Draw", "stack");
	//roiManager("Delete");
}
