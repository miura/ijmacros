// runs on 2 Channel time series stack
// ch1: signal
// ch2: nucleus
// intensity within the nuclear periphery zone in ch1 is measured 
// using a mask generated from ch2. 

// change this value to control rim ROI thickness
// Andrea ... initially was set 8. 2 is better for average intensity
var G_RimHalfWidth = 8;

macro "Segmentation BoniA" {
	run("Set Measurements...", 
		"area mean centroid bounding integrated stack redirect=None decimal=4");
	run("Clear Results");
	orginalTitle = getTitle();
	run("Split Channels");
	c1title = "C1-" + orginalTitle;
	selectImage(c1title);
	sigID = getImageID();	
	c2title = "C2-" + orginalTitle;
	selectImage(c2title);
	nucID = getImageID();	
	rimID = RimSegmentaton(nucID);
	selectImage(rimID);
	run("Invert", "stack");
	// arrays for plotting
	aveA = newArray(nSlices);
	sdA =  newArray(nSlices);
	maxA = newArray(nSlices);
	
	//run("Set Measurements...", "area mean standard min centroid bounding integrated stack redirect=None decimal=4");
	for (i = 0; i < nSlices; i++){
		selectImage(rimID);
		setSlice(i + 1);
		setAutoThreshold("Otsu dark");
		run("Create Selection");
		selectImage(sigID);
		setSlice(i+1);
		run("Restore Selection");
		List.setMeasurements;
		//print(List.getList);
		print("===Slice ", i+1);
		print("Mean Intensity: ", List.get("Mean"));
		print("Min:", List.get("Min"), " Max:", List.get("Max"));
		print("SD: ", List.get("StdDev"));		
		print("Total Area: ", List.get("Area"));
		//store results to arrays
		aveA[i] = List.get("Mean");
		sdA[i] = List.get("StdDev");
		maxA[i] = List.get("Max");	
	}
	Plotter(aveA, sdA, maxA);	
}

// Segmentation of nucleus image to extract rim zone. 
function RimSegmentaton(orgID){
	selectImage(orgID);
	run("8-bit");
	run("Duplicate...", "title=Filtered duplicate stack");
	filtID = getImageID();
	run("Gaussian Blur...", "sigma=1.5 stack");
	setAutoThreshold("Otsu dark");
	run("Convert to Mask", "calculate black");
	setAutoThreshold("Otsu dark");
	run("Analyze Particles...", "size=800-Infinity circularity=0.00-1.00 pixel show=Masks display exclude include stack");

	erodeID = getImageID();
	run("Invert LUT");
	rename("Mask_Inside");
	run("Fill Holes", "stack");
	run("Duplicate...", "title=Mask_Outside duplicate stack");
	dilateID = getImageID();

	selectImage(dilateID);
	dilation=G_RimHalfWidth;
	for(i=0;i<dilation;i++){
		run("Dilate", "stack");
	}

	selectImage(erodeID);
	selectImage("Mask_Inside");
	erosion=G_RimHalfWidth;
	for(i=0;i<erosion;i++){
		run("Erode", "stack");
	}
	imageCalculator("Subtract create stack", dilateID, erodeID);
	rimID = getImageID();
	//rename("rim");
	run("Invert", "stack");
	selectImage(filtID); close();
	selectImage(erodeID); close();
	selectImage(dilateID); close();		
	return rimID;
}

//Plots average intenity and max intensity. Two plots will be created. 
function Plotter(aveA, sdA, maxA){
	
	xA=newArray(aveA.length);
	for (i = 0; i < xA.length; i++) xA[i] = i;
	Plot.create("Mean Intensity", "frames", "Mean Intensity");
	Array.getStatistics(aveA, min, max, mean, stdDev);
	Plot.setLimits(0, aveA.length, 0, max*1.1 );
	Plot.setColor("blue");
	Plot.add("line", xA, aveA); 
	Plot.add("error bars", sdA); 
	Plot.show;

	Array.getStatistics(maxA, min, max, mean, stdDev);
	Plot.create("Max Intensity", "frames", "Max Intensity");	
	Plot.setLimits(0, aveA.length, 0, max*1.1 );
	Plot.setColor("red");
	Plot.add("line", xA, maxA); 
	Plot.show;
}

