///////////////////////////////////////////////////////////////////////////////////////////////
//// Name: 	FISH nuclei analyzer
//// Author:	Sébastien Tosi (IRB / Barcelona)
//// Version:	1.0
////
//// Usage: 	The user defined nucleus categories (given number of spots per channel). The
////		nuclei are detected and classified. Statistics on the cetegories of interest
////		are logged.
////
//// Input:	A stack holding Chan_0 (DAPI), Chan_1 (FISH1), Chan_2 (FISH2) and Chan_3 (FISH3)
//// Output:	Detected FISH spots, classified nuclei, statistics for the categories of nuclei
////		that are user defined.
////
//// Note: 	The default parameters are adjusted for the widefield dataset.
///////////////////////////////////////////////////////////////////////////////////////////////

DefaultGroups = 2;
DefaultValues = newArray(0,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0);
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
run("Set Measurements...", "area max centroid shape redirect=None decimal=2");	
roiManager("Associate", "true");
Groups = getNumber("How many nucleus categories do you want to define?",DefaultGroups);

// Dialog box for parameters
Dialog.create("FISH nuclei analyzer");
for(i=0;i<Groups;i++)
{
	Dialog.addMessage("Group "+d2s(i,0));
	Dialog.addCheckbox("Channel 1 (Red)?", true);
	Dialog.addNumber("Channel 1 multiplicity (0-2)", DefaultValues[0+3*i]);
	Dialog.addCheckbox("Channel 2 (Green)?", true);
	Dialog.addNumber("Channel 2 multiplicity (0-2)", DefaultValues[1+3*i]);
	Dialog.addCheckbox("Channel 3 (Blue)?", true);
	Dialog.addNumber("Channel 3 multiplicity (0-2)", DefaultValues[2+3*i]);
}
Dialog.addMessage("Spot detection");					
Dialog.addNumber("Nucleus smooth", 5); 					
Dialog.addNumber("Nucleus sensitivity", -0.1); 				
Dialog.addNumber("Nucleus area selectivity low", 0.65); 
Dialog.addNumber("Nucleus area selectivity high", 1.75); 			
Dialog.addNumber("Nucleus minimum circularity", 0.82);
Dialog.addNumber("Nucleus dilation iteration", 3);
Dialog.addNumber("Spot smoothing (pix)", 2); 				
Dialog.addNumber("Spot background radius (pix)", 5); 			
Dialog.addNumber("Chan 1 Spot level", 50);
Dialog.addNumber("Chan 2 Spot level", 50);
Dialog.addNumber("Chan 3 Spot level", 50);
Dialog.show();
Chan1Enable = newArray(Groups);
Chan1Mult = newArray(Groups);
Chan2Enable = newArray(Groups);
Chan2Mult = newArray(Groups);
Chan3Enable = newArray(Groups);
Chan3Mult = newArray(Groups);
SpotLevel = newArray(3);

// Read parameters from dialog box
for(i=0;i<Groups;i++)
{
	Chan1Enable[i] = Dialog.getCheckbox();
	Chan1Mult[i] = Dialog.getNumber();
	Chan2Enable[i] = Dialog.getCheckbox();
	Chan2Mult[i] = Dialog.getNumber();
	Chan3Enable[i] = Dialog.getCheckbox();
	Chan3Mult[i] = Dialog.getNumber();
}
NucSmooth = Dialog.getNumber();
NucSensitivity = Dialog.getNumber();
NucAreaSelectivityLow = Dialog.getNumber();
NucAreaSelectivityHigh = Dialog.getNumber();
NucMinCirc = Dialog.getNumber();
NucDilIter = Dialog.getNumber();
SpotLapSmooth = Dialog.getNumber();
SpotBackRadius = Dialog.getNumber();
SpotLevel[0] = Dialog.getNumber();
SpotLevel[1] = Dialog.getNumber();
SpotLevel[2] = Dialog.getNumber();

// Split stack
run("Stack to Images");

// Nucleus segmentation
selectImage("Chan_0");
run("FeatureJ Laplacian", "compute smoothing="+d2s(NucSmooth,1));
Chan_0_copyID = getImageID();
getMinAndMax(min,max);
setThreshold(min,NucSensitivity);	
run("Convert to Mask");
run("Fill Holes");
for(i=0;i<NucDilIter;i++)run("Dilate");
run("Analyze Particles...", "size=0-Infinity circularity="+d2s(NucMinCirc,2)+"-1.00 show=Nothing display exclude clear include");
Area = newArray(nResults);
for(i=0;i<nResults;i++)Area[i] = getResult("Area", i);
Area = Array.sort(Area);
MedianArea = Area[nResults/2];
print("Median area: "+d2s(MedianArea,0));
run("Watershed");
run("Analyze Particles...", "size="+d2s(MedianArea*NucAreaSelectivityLow,0)+"-"+d2s(MedianArea*NucAreaSelectivityHigh,0)+" circularity="+d2s(NucMinCirc,2)+"-1.00 show=Nothing exclude clear include add");	
selectImage(Chan_0_copyID);
close();
resetThreshold();
NNuc = roiManager("count");

// Spot detection
NbSpotsChan1 = newArray(NNuc);
NbSpotsChan2 = newArray(NNuc);
NbSpotsChan3 = newArray(NNuc);
for(i=1;i<4;i++)
{
	selectImage("Chan_"+d2s(i,0));
	run("FeatureJ Laplacian", "compute smoothing="+d2s(SpotLapSmooth ,0));
	LapID = getImageID();
	run("Invert");
	run("8-bit");
	rename("Lap");

	// Find spots
	run("Duplicate...", "title=Copy");
	run("Remove Outliers...", "radius="+d2s(SpotBackRadius,0)+" threshold="+d2s(SpotLevel[i-1],0)+" which=Bright");
	imageCalculator("Subtract create", "Lap","Copy");
	rename("SpotCandidates");
	setThreshold(1, 255);
	run("Convert to Mask");
	Mask2ID = getImageID();
	selectImage("Copy");
	close();
	
	// Spot measurements
	selectImage(Mask2ID);
	run("Set Measurements...", "area min centroid integrated redirect=None decimal=2");
	run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display exclude clear include");
	run("Select All");
	run("Set...", "value=0");
	run("Select None");
	for(j=0;j<nResults;j++)setPixel(round(getResult("X",j)),round(getResult("Y",j)),255);

	// Spot count
	run("Set Measurements...", "area min centroid integrated redirect=None decimal=2");
	for(j=0;j<NNuc;j++)
	{
		roiManager("select",j);
		getRawStatistics(nPixels, mean, min, max, std, histogram);
		NbSpots = nPixels-histogram[0];
		//if(NbSpots>2)NbSpots = 0; // Invalid
		if(i==1)NbSpotsChan1[j] = NbSpots;
		else 
		{
			if(i==2)NbSpotsChan2[j] = NbSpots;
			else if(i==3)NbSpotsChan3[j] = NbSpots;
		}
	}

	// Spot overlay
	setThreshold(1,255);
	run("Convert to Mask");
	run("Create Selection");
	selectImage(LapID);
	run("Restore Selection");
	// Check if selection
	if(selectionType>-1)
	{
		run("Enlarge...", "enlarge=1 pixel");
		roiManager("add");
		roiManager("select",roiManager("count")-1);
		if(i==1)roiManager("Set Color", "red");
		if(i==2)roiManager("Set Color", "green");
		if(i==3)roiManager("Set Color", "blue");
		//print(i);
		roiManager("Deselect");
	}	
	selectImage(LapID);
	close();
	selectImage(Mask2ID);
	close();
}
	
// Set color coded outlines of the nuclei
selectImage("Chan_0");
for(j=0;j<NNuc;j++)
{
	roiManager("select",j);
	ColorCode = "FF"+toHex(63+64*NbSpotsChan1[j])+toHex(63+64*NbSpotsChan2[j])+toHex(63+64*NbSpotsChan3[j]);
	run("Properties... ", "name=Nuc"+d2s(j,0)+" stroke="+ColorCode+" width=1 fill=none");			
	roiManager("update");
}
run("Images to Stack", "name=Stack title=[] use");
roiManager("Show All without labels");	

// Associate spots to slice
for(j=2;j<=4;j++)
{
	roiManager("select",roiManager("count")-5+j);
	setSlice(j);
	roiManager("update");
}
setSlice(1);

// Find candidate nuclei
rename("Montage");
run("Clear Results");
roiManager("Deselect");
roiManager("Measure");
SelectedX = newArray(NNuc*Groups);
SelectedY = newArray(NNuc*Groups);
SelectedN = newArray(Groups);
NbSelected = 0;
for(i=0;i<Groups;i++)
{
	for(j=0;j<NNuc;j++)
	{
		if( ((Chan1Enable[i] == false)||(Chan1Mult[i] == NbSpotsChan1[j]))&&((Chan2Enable[i] == false)||(Chan2Mult[i] == NbSpotsChan2[j]))&&((Chan3Enable[i] == false)||(Chan3Mult[i] == NbSpotsChan3[j])) )
		{
			SelectedX[NbSelected] = getResult("X",j);
			SelectedY[NbSelected] = getResult("Y",j);
			NbSelected++;
			SelectedN[i]++;
		}
	}	
}
for(i=0;i<Groups;i++)print("Frequency of category "+d2s(i,0)+": "+d2s(100*SelectedN[i]/NNuc,2)+"% ("+d2s(SelectedN[i],0)+"/"+d2s(NNuc,0)+")");
SelectedX = Array.trim(SelectedX, NbSelected);
SelectedY = Array.trim(SelectedY, NbSelected);

// Selection of target nuclei
setTool("multipoint");
run("Colors...", "foreground=white background=black selection=white");
makeSelection("point",SelectedX,SelectedY);