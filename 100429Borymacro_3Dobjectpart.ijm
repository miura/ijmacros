
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

macro "-"{}

// uses threshold adjustment tool made for nuc distance map to segment dots in each time point. 
// criteria for the adjustment is based on the segmented dot size (total)
//in Bory's prokject, this should be done after FFT band pass filter
macro "adjusted threshold segmentation"{
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

	adjustedTHlowA[0] = tframes;  //the first value in this array contains the number of time points. 

	setBatchMode(true);
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
		if (i>0) 	run("Concatenate...", "stack1=bin stack2=single title=combined");
		rename("bin");			

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

macro "Measure 3D-t binary image"{
	zframes = getNumber("Z frames?", 8);
	tframes = nSlices/zframes;
	cchannel = 0;
	Stack.getDimensions(width, height, channels, slices, frames);
	stackID = getImageID();
	run("Clear Results");
	counter =0;
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
