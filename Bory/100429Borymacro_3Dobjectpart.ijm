
requires("1.43u");

//run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
//run("Properties...", "channels=1 slices=8 frames=46 unit=pixel pixel_width=1.0000 pixel_height=1.0000 voxel_depth=3 frame=[NaN sec] origin=0,0");

var GminimumFISHvoxelSize = 2;
var Orgxyscaling =1;
var Orgxyscaling = 1;
var Orgzscaling = 1;
var Orgchannels =1;
var Orgzframes =1;
var Orgtframes =1;

var xyscaling = 1;
var zscaling = 3;
var zfactor =3;
var Gunit = "";
var zframes = 8;
var tframes = 46;
var channels = 1;
var adjustedTHlowA = newArray(1000); //stores threshold value after adjustment  //the first value in this array contains the number of time points. 

var Gmaxspotvoxels = 55;
var Gminimumvoxels = 35;

var GorgID =0;
var Gbin3DID =0;

var Gminvoxelsize4measure =7; //smallest volume to be included in measurments. 

var Gtitle ="ch0";	//ch0
var G_GID = 0;
var Rtitle = "ch1";	//ch1
var G_RID = 1;

macro "Load DV file"{
	requires("1.43d");
	OpenDVch(1, "none");
}

macro "Load DV file and Preprocess"{
	requires("1.43d");
	path = OpenDVch(0, "none");
	run("Preprocess ChromosomeDots");
	OpenDVch(1, path);
	run("Preprocess ChromosomeDots");
	
}


function OpenDVch(ch, gpath){
	run("Bio-Formats Macro Extensions");
	if (gpath == "none")
		path = File.openDialog("Select a DV File");
	name = File.getName(path);
	dir = File.getParent(path);	
	//DAPIch = getNumber("DAPI ch=?", 0);
	//FISHch = getNumber("FISH ch=?", 1);

	q = File.separator; //090912

	//workdir = getDirectory("Choose a work space directory to save resulting files");

	Ext.setId(path);
	Ext.getSeriesCount(seriesCount);
	Ext.getCurrentFile(file);
	Ext.setSeries(0);
	Ext.getSeriesName(seriesName);
	Ext.getSizeT(sizeT);
	Ext.getSizeZ(sizeZ);
	Ext.getSizeC(sizeC);
	print(sizeT, sizeZ, sizeC);

	XscaleKey = "X element length (in um)"; //seriesName+ " - dblVoxelX - Voxel-Width";
	YscaleKey = "Y element length (in um)"; // seriesName+ " - dblVoxelY - Voxel-Height";
	ZscaleKey =  "Z element length (in um)"; //seriesName+ " - dblVoxelZ - Voxel-Depth";
	
	Ext.getMetadataValue(XscaleKey, xscale);
	Ext.getMetadataValue(YscaleKey, yscale);
	Ext.getMetadataValue(ZscaleKey, zscale);
	print(xscale, yscale, zscale);

	setBatchMode(true);
	for (j=0; j<sizeT; j++){
		for (i=0; i<sizeZ; i++){
			currentZch0 = j*sizeZ+i*sizeC;
			Ext.openImage(""+name +"ch"+ch, currentZch0+ch);
			slicelabel = getMetadata("Label");
			if (currentZch0 == 0)
				stackID=getImageID();
			else	{
				run("Copy");
				close;
				selectImage(stackID);
				run("Add Slice");
				run("Paste");
				
			}
			setMetadata("Label", "c="+ch+" z="+i + " t=" + j);
		}
	}	
	Stack.setDimensions(1, sizeZ, sizeT);
	setVoxelSize(xscale, yscale, zscale, "um");
	Ext.close();
	setBatchMode(false);

	print("File:"+ file);
	print("series total number" + seriesCount);
	return path;

}

//======== scales, settings =======
macro "settings"{}
macro "... Store original Scale and Dimensions"{
	StoreOriginalScaleDims();
}
macro "... restore original scaling"{
	setVoxelSize(xyscaling , xyscaling , zscaling , Gunit);
	Stack.setDimensions(channels, zframes, tframes);
}

function StoreOriginalScaleDims(){
	getVoxelSize(Orgxyscaling ,Orgxyscaling , Orgzscaling , Gunit);
	Stack.getDimensions(width, height, Orgchannels, Orgzframes, Orgtframes);
}

function reStoreOriginalScaleDims(){
	setVoxelSize(Orgxyscaling ,Orgxyscaling , Orgzscaling , Gunit);
	Stack.setDimensions(Orgchannels, Orgzframes, Orgtframes);
}


//set voxel to 1:1:1 scale so this could be duplicated easily by settign the slice range. 
function StoreAndClearScalingDimension(){
	getVoxelSize(xyscaling , xyscaling , zscaling , unit);
	Stack.getDimensions(width, height, channels, zframes, tframes);
	zfactor = zscaling/xyscaling;
	setVoxelSize(1, 1, zfactor, "pixels");
	Stack.setDimensions(channels, zframes*tframes, 1);
}

///////////////////////////////  getting windows ////////////////////////////////////
macro "-"{}

macro "Assign Windows  [f1]" {
	requires("1.43u");	//090526 for stack function
	twoImageChoice();
	selectWindow(Gtitle);	//ch0
	G_GID = getImageID();
	selectWindow(Rtitle);	//ch1
	G_RID = getImageID();
//	GThSignalL = FISHthresholdFinderisoData(G_RID);	//090526
//	GThSignalH =255;	//090526
//	resetThreshold();	//090526
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
 	//Dialog.addNumber("number2:", 0);
	Dialog.addChoice("Ch 0", wintitleA);
	Dialog.addChoice("Ch 1", wintitleA);
 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 = Dialog.getNumber();;
	Gtitle = Dialog.getChoice();
 	Rtitle = Dialog.getChoice();
	print("ch0:"+Gtitle);
	print("ch1" + Rtitle);
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

///////////////////////////////  getting windows end ////////////////////////////////////

macro "-"{}

var Gorgch0ID;
var Gorgch1ID;
var Gbin3Dch0ID; 
var Gbin3Dch1ID;
  
macro "Analyze dot-dot distance (cropped single cell frames)"{
	selectImage(G_GID);
	Gorgch0ID = getImageID();
	StoreOriginalScaleDims();
	StoreAndClearScalingDimension();
	thadjustSegmentation();
	Gbin3Dch0ID = getImageID();
	Stack.setDimensions(Orgchannels, Orgzframes, Orgtframes);
	selectImage(Gorgch0ID);
	reStoreOriginalScaleDims();

	selectImage(G_RID);
	StoreAndClearScalingDimension();
	Gorgch1ID = getImageID();
	thadjustSegmentation();
	Gbin3Dch1ID = getImageID();
	Stack.setDimensions(Orgchannels, Orgzframes, Orgtframes);
	selectImage(Gorgch1ID);
	reStoreOriginalScaleDims();

	selectImage(Gorgch0ID);
	measure3Dt(0);
	selectImage(Gorgch1ID);
	measure3Dt(1);
	LinkerCore();	
}



// uses threshold adjustment tool made for nuc distance map to segment dots in each time point. 
// criteria for the adjustment is based on the segmented dot size (total)
//in Bory's prokject, this should be done after FFT band pass filter
macro "Auto-Threshold Adjusting Dot Segmentation"{
	StoreOriginalScaleDims();
	GorgID = getImageID();
	StoreAndClearScalingDimension();
	thadjustSegmentation();
	Gbin3DID = getImageID();
	Stack.setDimensions(Orgchannels, Orgzframes, Orgtframes);
	selectImage(GorgID);
	reStoreOriginalScaleDims();
}

//need to be done after above
macro "... check detected dots"{
	selectImage(Gbin3DID);
	op ="order=xyczt(default) channels=1 slices="+Orgzframes+" frames="+Orgtframes+" display=Grayscale";
	run("Stack to Hyperstack...", op);
	opz = "start=1 stop="+Orgzframes+" projection=[Max Intensity] all";
	run("Z Project...", opz);
	projbinID = getImageID();
	run("Make Montage...", "columns=8 rows=6 scale=1 first=1 last=46 increment=1 border=0 font=10");
	rename("MontBin");

	selectImage(GorgID);
	run("Stack to Hyperstack...", op);
	selectImage(GorgID);
	run("Z Project...", opz);
	projorgID = getImageID();
	run("Make Montage...", "columns=8 rows=6 scale=1 first=1 last=46 increment=1 border=0 font=10");
	rename("MontOrg");
	
	run("Merge Channels...", "red=MontBin green=MontOrg blue=*None* gray=*None*");

	//run("Duplicate...", "title=bin-1 duplicate range=1-368");
	//temp3DbinID = getImageID();
	//run("Divide...", "value=255 stack");
	//imageCalculator("Multiply create stack", GorgID ,temp3DbinID);
	

}

macro "... create masked original"{
	selectImage(Gbin3DID);
	run("Duplicate...", "title=bin-1 duplicate range=1-"+nSlices);
	temp3DbinID = getImageID();
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", GorgID ,temp3DbinID);
}



function thadjustSegmentation(){
	zframes = Orgzframes;
	if (Orgzframes ==1) zframes = getNumber("Z frames?", 8);
	tframes = nSlices/zframes;
	cchannel = 0;
	stackID = getImageID();
	run("Duplicate...", "title=binstack duplicate");
	binstackID = getImageID();
	//selectImage(stackID);
	adjustedTHlowA[0] = tframes;  //the first value in this array contains the number of time points. 

	//setBatchMode(true);
	counter =0;
	
	for(i=0; i<tframes; i++){
		print("Time Point: "+i);
		selectImage(stackID);
		op = "title=single duplicate range="+i*zframes + 1+"-"+(i+1)*zframes;
		print(op);
		run("Duplicate...", op);
		//selectImage(singleID);
		singleID = getImageID();
		opz ="start=1 stop="+zframes+" projection=[Max Intensity]";
		run("Z Project...", opz);
		setAutoThreshold("Shanbhag dark");
		getThreshold(lower, upper);
		close();
		selectImage(singleID);
		lowadjusted = FISHthlowAdjuster(lower);
		adjustedTHlowA[i+1] =  lowadjusted;
		setThreshold(lowadjusted, 255);
		run("Convert to Mask", "  black");
		copycontent(binstackID, singleID, i, zframes);
		//if (i>0) 	run("Concatenate...", "stack1=bin stack2=single title=combined");
		//rename("bin");
		selectImage(singleID); close();			

	}
	//setBatchMode("exit and display");

}

function copycontent(binstackID, singlestackID, timepoint, zframes){
	setBatchMode(true);
	for(i=0; i<zframes; i++){
		selectImage(singlestackID);
		setSlice(i+1);
		run("Select All"); run("Copy");
		selectImage(binstackID);
		setSlice(zframes*timepoint+1+i);
		run("Paste");		
	}
	setBatchMode("exit and display");
}




//090526 not working yet 
//090813 working
//GThSignalL is not touched
// works on window with FISH signal expected to be only one or two. (single nucleus crop)
function FISHthlowAdjuster(currentThreshold){
	maxspotvoxels = Gmaxspotvoxels ;
	minimumvoxels = Gminimumvoxels;
	maxloops = 50;
	originalstackID = getImageID();
	setBatchMode(true);
	//op = "title=[tempFISHthreshold] duplicate range=1-"+nSlices;
	op = "title=[tempthreshold] duplicate";
	run("Duplicate...", op);
	tempID=getImageID();
	setThreshold(currentThreshold, 255);
	run("Convert to Mask", "  black");
	localthres = currentThreshold;
	voxelnum =Return255num();
	print("      FISH voxels before adjustment = "+voxelnum + "(th="+localthres);
	voxelsA = newArray(maxloops);
	thresadjustA = newArray(maxloops);

	loopcount =0;
	while (((voxelnum <minimumvoxels) || (voxelnum >maxspotvoxels)) && (loopcount <maxloops))  {
		selectImage(tempID);
		 close();
		if (voxelnum<minimumvoxels) localthres--;
		if (voxelnum>maxspotvoxels) localthres++;
		selectImage(originalstackID);
		run("Duplicate...", op);
		tempID=getImageID();
		setThreshold(localthres, 255);
		run("Convert to Mask", "  black");
		voxelnum =Return255num();
		voxelsA[loopcount] = voxelnum;
		thresadjustA[loopcount] = localthres;
		loopcount++;
		//print("      tresh ="+localthres + " Voxels = "+voxelnum );
	}
	selectImage(tempID);
	close();
	if (loopcount>=maxloops) {
		if (voxelsA[loopcount-1]>voxelsA[loopcount-2]) {
			localthres = thresadjustA[loopcount-1];
			currentvox =voxelsA[loopcount-1];
		} else {
			localthres = thresadjustA[loopcount-2];
			currentvox =voxelsA[loopcount-2];
		}
		print("      ...Looped out: "+loopcount + "  current voxels ="+currentvox ); 
	} else {
		print("      ...converged after "+loopcount +" iterations"); 

	}
	setBatchMode("exit and display");
	//selectImage(originalstackID);
	//setThreshold(localthres, 255);
	return localthres;
} 

//090526
function Return255num() {
	returnflag =0;
	for(i=0; i<nSlices; i++) {
		setSlice(i+1);
		getRawStatistics(nPixels, mean, min, max, std, histogram);
		returnflag +=histogram[255];
	}
	return returnflag;
}


//090728
// find singular signals, and recursivlely increase the minimum size until nuber of dots are less than or euqal to 2
// this automatically leaves less than or euqals to 2 dots, largest of existing particles. 
function KreturnOptimizedMinimumVoxleCutoff(sigID){
		dots255 =10; //dummy number
		minvoxels = GminimumFISHvoxelSize;
		selectImage(sigID);
		setBatchMode(true);
		while(dots255 >2) {
			selectImage(sigID);
			//op = "threshold=128 slice="+nSlices+" min="+minvoxels +" max=4000 new_results geometrical dot=1 font=12"; //090728
 			op = "threshold=128 slice=1 min="+GminimumFISHvoxelSize+" max=5000 new_results dot=3 font=12"
			run("Object Counter3D", op); //090728 for getting single point, require object counter 3D
			singularsigID = getImageID();	//090728	use sigID
			run("Multiply...", "value=255 stack");	//090728
			run("8-bit");	//090728
			dots255 = 	 ReturnStackHistogram255thValue();		
			//if (minvoxels == GminimumFISHvoxelSize)	print("Minimum Voxel:"+minvoxels+" --> dots:"+dots255 );
			close();
/*			if(dots255 <=2) {
				print("Minimum Voxel:"+minvoxels+" --> dots:"+dots255 );
			}
*/			minvoxels ++;
		}
		setBatchMode("exit and display");
		return (minvoxels -1);
}

macro "Measure 3D-t binary image Ch0"{
	measure3Dt(0);
}
macro "Measure 3D-t binary image Ch1"{
	measure3Dt(1);
}
	
function measure3Dt(currCh){
	cchannel = currCh;
	if (nSlices==1) exit();
	Stack.getDimensions(width, height, channels, slices, frames);
	if (frames ==1) zframes = getNumber("Z frames?", 8);
	else zframes=slices;
	tframes = nSlices/zframes;
	stackID = getImageID();

	if (currCh ==0) 
		run("Clear Results");
	counter =nResults;

	setBatchMode(true);
	for(i=0; i<tframes; i++){
		newImage("singletimepoint", "8-bit Black", width, height, zframes);
		singleID = getImageID();
		for (j=0; j<zframes; j++){
			selectImage(stackID);
			setSlice(i*zframes + 1 + j);
			run("Select All");
			run("Copy");
			selectImage(singleID);
			setSlice(1 + j);
			run("Paste");
		}
		selectImage(singleID);
		dotsnum = GetDotCoordinatesV2();
		if (dotsnum >0) {
			for(j =0; j<res3DobjA[0]; j++){
				setResult("timepoint", counter, i);
				setResult("channel", counter, cchannel);
				setResult("dotID", counter, j);
				setResult("volume", counter, res3DobjA[j* Gpnum + 1]);
				setResult("surface", counter, res3DobjA[j* Gpnum + 2]);
/* old version object3D
				setResult("intensity", counter, res3DobjA[j* Gpnum + 3]);				
				setResult("x", counter, res3DobjA[j* Gpnum + 4]);	
				setResult("y", counter, res3DobjA[j* Gpnum + 5]);
				setResult("z", counter, res3DobjA[j* Gpnum + 6]);
*/
				setResult("intTotal", counter, res3DobjA[j* Gpnum + 5]);
				setResult("intMean", counter, res3DobjA[j* Gpnum + 6]);				
				setResult("x", counter, res3DobjA[j* Gpnum + 11]);	
				setResult("y", counter, res3DobjA[j* Gpnum + 12]);
				setResult("z", counter, res3DobjA[j* Gpnum + 13]);

				setResult("cx", counter, res3DobjA[j* Gpnum + 17]);	
				setResult("cy", counter, res3DobjA[j* Gpnum + 18]);
				setResult("cz", counter, res3DobjA[j* Gpnum + 19]);
				counter++;
			}
			updateResults();
		}
		selectImage(singleID);
		close();
	}
	setBatchMode("exit and display");
}

macro "... plot detected dots"{
	if (nResults <=1) exit("Measurment of dot not finished");
	if (nSlices != Orgzframes * Orgtframes) exit("is this really the stack you want to use for plotting dots?");
	op ="order=xyczt(default) channels=1 slices="+Orgzframes+" frames="+Orgtframes+" display=Grayscale";
	run("Stack to Hyperstack...", op);
	opz = "start=1 stop="+Orgzframes+" projection=[Max Intensity] all";
	run("Z Project...", opz);
	run("RGB Color");
	run("Colors...", "foreground=red background=black selection=yellow");
	for(i=0; i<nResults; i++){
		setSlice(getResult("timepoint", i)+1);
		makeRectangle(getResult("x", i), getResult("y", i), 1, 1);
		run("Fill", "slice");
	}
	run("Colors...", "foreground=white background=black selection=yellow");
}



//processes single time point 3D stack, binary (segmented)
macro "test 3D dot detection single time point binary"{
	GetDotCoordinatesV2();
}

//var Gpnum =6; // number of parameters per dot for Object3D counter
var Gpnum =25; // number of parameters per dot for Object3D counter	case of new version

var res3DobjA = newArray(Gpnum*200+1); //storing 3D obejct counter one dot would occupy Gpnum oof parameters
				// [0] would contain number of dots. 
/*
0 number of dots detected
1 volume
2 surface area	(surface area is not really reliable with ImageJ plugin, maybe is OK in FIJI)
3 total intensity
4 x coordinate
5 y coordinate
6 z coordinate

1- 7 should be then iterated for number of dots detected. 
*/

/* in case of new version, results table consists of
0 count
1 volume
2. Surface
3 Nb. of obj voxels
4 Nb of surf voxels
5 intDen
6 Mean
7 StdDev
8 Median
9 Min
10 Max
11 centx
12 centy
13 centz
14 --
15
16
17 density weighted x
18 density weighted y
19 density weighted z
20 BX
21BY
22BZ
23 bw
24 bh
25 bd
*/

// for detecting dots in single frame
//works with binarized image
function GetDotCoordinatesV2(){
	wintitle = getTitle();
	minvoxelsize = Gminvoxelsize4measure ;
	//should check scale here. 
	//following option is specific to Fiji
	run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
	//below is for Fiji pluign
	//run("3D Objects Counter", "threshold=128 slice=1 min.="+minvoxelsize +" max.=480000 statistics");
	run("3D Objects Counter", "threshold=1 slice=1 min.="+minvoxelsize +" max.=480000 statistics");

	//below is for ImageJ plugin
	//run("Object Counter3D", "threshold=128 slice=1 min="+minvoxelsize +" max=480000 new_results dot=3 font=12");
	//resultwin = "Results from " + wintitle; //ImageJ
	resultwin = "Statistics for " + wintitle; //Fiji
	selectWindow(resultwin);
	//print(getInfo("window.contents"));
	tabletext = getInfo("window.contents");
	tableA = split(tabletext, "\n");
	print("detected dot number:"+tableA.length-1);
	//for (i=0; i<tableA.length; i++) print(tableA[i]);
	res3DobjA[0] = tableA.length-1;
	if (res3DobjA[0]>0) {
		for (i=1; i<tableA.length; i++){
			paraA=split(tableA[i]);
			for (j=0; j<Gpnum; j++) res3DobjA[(i-1)*Gpnum+j+1] = parseFloat(paraA[j+1]);
		}
		//for(i=0; i<res3DobjA[0]*Gpnum+1; i++) print(res3DobjA[i]);
		tA=newArray(res3DobjA[0]*Gpnum + 1);
		sortDotArrays(res3DobjA, tA);
		for (i=0; i<tA[0]; i++){
			rowinfo = "";
			for (j = i*Gpnum+1; j<(i+1)*Gpnum+1; j++) rowinfo = rowinfo + "..."+tA[j];
			print(rowinfo);
			for (j = i*Gpnum+1; j<(i+1)*Gpnum+1; j++) res3DobjA[j] = tA[j];
		}
	}
	
	return res3DobjA[0]; // number of dots detected
}

macro "test sorting decending"{
	res3DobjA[0] = 6;
	res3DobjA[1] = 10;res3DobjA[2] = 1;res3DobjA[3] = 1;res3DobjA[4] = 1;	
	res3DobjA[7] = 30;
	res3DobjA[13] = 30;	
	res3DobjA[19] = 50;res3DobjA[20] = 60;res3DobjA[21] =80;res3DobjA[22] = 70;
	res3DobjA[25] = 25;
	res3DobjA[31] = 35;	
	tA=newArray(res3DobjA[0]*Gpnum + 1);
	sortDotArrays(res3DobjA, tA);
	for (i=0; i<tA.length; i++) print(tA[i]); 	
}

//sort content of array (one dot with 6 parameters are sorted according to volume in decending order)
function sortDotArrays(res3DobjA, resSortedA){ 
	volA = newArray(res3DobjA[0]);
	indA = newArray(res3DobjA[0]);
	flagA = newArray(res3DobjA[0]);
	if (res3DobjA[0]>1){

		for (j=0; j<indA.length; j++){
			maxvol =-1;
			maxindex = 0;
			
			for (i = 0; i<indA.length; i++){
				volnow = res3DobjA[i*Gpnum+ 1];
				if (flagA[i] != 1){
					//if ((volA[j-1]>=volnow) && (volnow>maxvol)){
					if (volnow>maxvol){
						maxvol = volnow;
						maxindex =i;
					}
				}
			}
			volA[j] = maxvol;
			indA[j] = maxindex;
			flagA[maxindex] =1;
		}
	} else {
		volA[0] =  resSortedA[1];
		indA[0] = 0;
	}
	for(i=0; i<volA.length; i++){
		print(""+indA[i]+" : "+volA[i]);
	}
	for (i = 0; i< res3DobjA[0]; i++){
		resSortedA[0] = res3DobjA[0];
		for (j=0; j<Gpnum; j++) resSortedA[1+i*Gpnum+j] = res3DobjA[1+indA[i]*Gpnum+j];
	}
}

/*	
	selectedline = 1; //default, only one dot detected.
	if (tableA.length > 2) {
		print("More than two dots detected in "+wintitle);
		volumeA = newArray(tableA.length);
		for (i=1; i<tableA.length; i++) {
			templineA = split(tableA[i], "\t");
			volumeA[i] = templineA[1];
		}
		volume =0; 
		index = 0;
		for (i=1; i<volumeA.length; i++){
			if (volumeA[i] > volume) {
				volume = volumeA[i];
				index = i;
			}
		}
		selectedline = index; 
		print("   ... Index selected:"+selectedline);
	}
	if (tableA.length == 1) {	//when no dot detectd, fill -1 for return values
		pos3DA[0] = -1; //x
		pos3DA[1] = -1; //y
		pos3DA[2] = -1; //z

	} else {
		lineA = split(tableA[selectedline], "\t");
			//pos3DA[0] = lineA[4]; //x  these are cases when using ImageJ
			//pos3DA[1] = lineA[5]; //y
			//pos3DA[2] = lineA[6]; //z

		pos3DA[0] = lineA[11]; //x these are cases when using Fiji 
		pos3DA[1] = lineA[12]; //y
		pos3DA[2] = lineA[13]; //z

	}
	return (tableA.length-1); //number of dots detected.
*/	
}

//***** distance by dot-dot pairing ******

// use modified "stable marrige matching" algorithm?
// 

//dots0posA single array with dot positions
//dots0posA and dots1posA should have same number of points. 
funciton ConvertRanks(dots0posA, dots1posA){
	 
}


funciton MarrigeMatchAlgorithm(dots0A, dots0distA dots1A, ){

}

// matching by cost function
funciton Ranks(dots0posA, dots1posA, resultpairA){
	N0 = dots0posA.length/3;
	N1 = dots1posA.length/3;
	if (N0 >= N1) matchnum = N1;
	else matchnum = N0;
	currmatch = 0;
	for (i=0; i<N0; i++){
		for (j=0; j<)
		for(k=0; k<3; k++) dist = 

	}

}

macro "choose" {
	print(mathChoose(5, 3));
}
function mathChoose(n, k){
	factn =0;
	for (i=1; i<=n; i++) factn *= i;
	factk =0; 
	for (i=1; i<=k; i++) factk *= i;
	factnk = 0;
	for(i=1; i<=(n-k); i++) factnk *=i;
	return factn/factk/factnk;
}


/*
public static long BinomialCoefficient(long n, long k)
{
    if (n / 2 < k)
        return BinomialCoefficient(n, n - k);

    if (k > n)
        return 0;

    if (k == 0)
        return 1;

    long result = n;
    for (long d = 2; d <= k; d++)
    {
        long gcd = (long)BigInteger.GreatestCommonDivisor(d, n);
        result *= (n / gcd);
        result /= (d / gcd);
        n++;
    }

    return result;
}
*/

/// for pairing analysis. 100517

var totalTimepoints = tframes ;
var connectArray =newArray(tframes*14); 3coords ch0, ch1 each, + distance for 2 sets (14) * timepoints. 
macro "-"{};

macro "connect dots in different channels"{
	LinkerCore();	
}

function LinkerCore(){
	if (nResults==0) exit("not measured??");
	for(i=0; i<connectArray.length; i++) connectArray[i] =-1;
	 DotLinker(tframes);
	setColor(255, 255, 255);
	for (i=0; i<tframes; i++){
		//setSlice(i+1);
		pstr = "time:" + i  + "\n"
			+ "   ch0: "	+ connectArray[i*14 ]
				+", "	+ connectArray[i*14 +1] 
 				+", "	+ connectArray[i*14 +2]
			+ "\n   ch1: "	+ connectArray[i*14 +3]
				+", "	+ connectArray[i*14 +3 +1] 
 				+", "	+ connectArray[i*14 +3 +2];
		//drawLine(connectArray[i*14], connectArray[i*14+1], connectArray[i*14+3], connectArray[i*14+4]);
		if (connectArray[i*14 +7] !=-1) {
			pstr = pstr + "\n   ch0: "+   connectArray[i*14 +7]
				+", "+   connectArray[i*14 +7+1]
				+", "+   connectArray[i*14 +7+2]
				+ "\n   ch1: "+   connectArray[i*14 +7+3]
				+", "+   connectArray[i*14 +7+3+1]
				+", "+   connectArray[i*14 +7+3+2];
				//drawLine(connectArray[i*14+7], connectArray[i*14+7+1], connectArray[i*14+7+3], connectArray[i*14+7+4]);

		}
		print(pstr);
 
	}
}

function DotLinker(tframes){
	for (i=0; i<tframes; i++) {
		ch0dots = returnDotNumber(0, i);
		ch1dots = returnDotNumber(1, i);
		//print(i +":  Ch0 dots:", ch0dots, "- Ch1 dots:", ch1dots);
		
		if ((ch0dots != 0) && (ch1dots != 0)) {

			if ((ch0dots == 1) && (ch1dots == 1)) {
				StoreCoordinates(connectArray, i, 0, 0, 0);
				StoreCoordinates(connectArray, i, 1, 0, 0);
			} else {
				if ((ch0dots >= 2) && (ch1dots >= 2)) {
					flag = compare2x2(i);
					if (flag ==1) {
						StoreCoordinates(connectArray, i, 0, 0, 0);
						StoreCoordinates(connectArray, i, 1, 0, 0);
						StoreCoordinates(connectArray, i, 0, 1, 1);
						StoreCoordinates(connectArray, i, 1, 1, 1);
					} else {
						StoreCoordinates(connectArray, i, 0, 0, 0);
						StoreCoordinates(connectArray, i, 1, 0, 1);
						StoreCoordinates(connectArray, i, 0, 1, 1);
						StoreCoordinates(connectArray, i, 1, 1, 0);
					}
				} else {		//either one of them is only one. 
					flag = compare2x1(i);
					if (flag ==1) {
						StoreCoordinates(connectArray, i, 0, 0, 0);
						StoreCoordinates(connectArray, i, 1, 0, 0);
					} else {
						if (flag ==2) {
							StoreCoordinates(connectArray, i, 0, 0, 0);
							StoreCoordinates(connectArray, i, 1, 1, 0);
						} else {
							StoreCoordinates(connectArray, i, 0, 1, 0);
							StoreCoordinates(connectArray, i, 1, 0, 0);
						}
					}
				}
			}
		}

	}
}

function returnDotNumber(curchannel, tpoint){
	counter =0; 
	for (i=0; i<nResults;i++) {
		if ((getResult("timepoint",i)==tpoint) && (getResult("channel",i)==curchannel)) counter++;
	}
	return counter;
}

function returnDotIndex(curchannel, tpoint, dotID){
	retindex =0;
	for (i=0; i<nResults;i++) {
		if ((getResult("timepoint",i)==tpoint) && (getResult("channel",i)==curchannel) && (getResult("dotID",i)==dotID)) retindex=i;
	}
	return retindex ;
}

function StoreCoordinates(sA, timepoints, chrchannel, dotID, offset){
	key = timepoints * 14;
	index =  returnDotIndex(chrchannel, timepoints, dotID);
	sA[key+ offset*7 +chrchannel*3 ] =  getResult("x", index);
	sA[key+ offset*7+chrchannel*3+1] =  getResult("y", index);
	sA[key+ offset*7+chrchannel*3+2] =  getResult("z", index);
}

function compare2x2(timepoint){
	ch0id0 = returnDotIndex(0, timepoint, 0);
	ch0id1 = returnDotIndex(0, timepoint, 1);
	ch1id0 = returnDotIndex(1, timepoint, 0);
	ch1id1 = returnDotIndex(1, timepoint, 1);
	combi01 = returnDistance(ch0id0,  ch1id0) + returnDistance(ch0id1,  ch1id1);
	combi02 = returnDistance(ch0id0,  ch1id1) + returnDistance(ch0id1,  ch1id0);
	flag =0;
	if (combi01 < combi02 ) flag =1;
	else flag =2;
	return flag;
}

function compare2x1(timepoint){
	ch0dots = returnDotNumber(0, timepoint);
	ch1dots = returnDotNumber(1, timepoint);
	ch0id0 = returnDotIndex(0, timepoint, 0);
	ch1id0 = returnDotIndex(1, timepoint, 0);
	flag =0;
	if (ch0dots ==1) {
		ch1id1 = returnDotIndex(1, timepoint, 1);
		combi01 = returnDistance(ch0id0,  ch1id0) ;
		combi02 = returnDistance(ch0id0,  ch1id1) ;
		if (combi01<combi02) flag= 1;
		else flag = 2;
	} else {
		ch0id1 = returnDotIndex(0, timepoint, 1);
		combi01 = returnDistance(ch0id0,  ch1id0) ;
		combi02 = returnDistance(ch0id1,  ch1id0) ;
		if (combi01<combi02) flag= 1;
		else flag = 3;
	}
	return flag;
}

function returnDistance(index1, index2){
	sqd = pow(getResult("x", index1) - getResult("x", index2), 2) 
		+ pow(getResult("y", index1) - getResult("y", index2), 2) 
		+ pow(getResult("z", index1) - getResult("z", index2), 2);
	return pow(sqd, 0.5);
} 

macro "test plotting links"{
	for(i=0; i<tframes; i++){
		
	}

}





