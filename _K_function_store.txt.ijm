// Collection of frequently used functions
//Kota Miura (EMBL Heidelberg)
/*
	1.  STRING managements

	2. User Interface

var G_Gtitle="ig1";	
var G_Rtitle="ig2";	

	3.  PROFILE PLOTTING

var PlotRange_y_max=-50000;
var PlotRange_y_min=50000;

	4. Arrays
	4.5.  Array and Result Table

var G_w=10;	// usually equals to nResults 

	5.  Check states

	6. Math

	- angle measurements

	7. results table

	8. File I/O

	9. Memory Statuts

	10. Time
*/



//	******************************	1.  STRING managements	******************************

//digits padding
function leftPad(n, width) {
    s =""+n;
    while (lengthOf(s)<width)
        s = "0"+s;
    return s;
}

macro "string space to underscore"{
	stringin=getString("test string", "test test");
	print(stringSpace2underscore(stringin));
}

function stringSpace2underscore(stringin){
	print(stringin);
	while (indexOf(stringin, " ")>-1){
		indexofspace=indexOf(stringin, " ");
		//print(indexofspace);
		stringin= substring(stringin, 0,indexofspace) +"_"+substring(stringin, indexofspace+1, lengthOf(stringin));
	}
	print("   ---> "+stringin);
	return stringin;	
}


function returnPerkEl_Prefix1(fullfilename) {
	substr1="_";	
	substr2=".";
	print(fullfilename);
	UndScoreindex=indexOf(fullfilename,substr1);
	Dotindex=indexOf(fullfilename,substr2);	
	pref1start=0;
	//pref1end=UndScoreindex;	//out 060331
	pref1end=Dotindex-4;
	//print(UndScoreindex);
	//print(Dotindex);
	pref1=substring(fullfilename,pref1start,pref1end);
	return pref1;
}

//070222 Kota: removes file name extention such as ".tif" and return the 
// prefix. "extensiton" will be removed.
function removeExtention(fullfilename,extensiton) {
	substr2=extensiton;	//".";
	print(fullfilename);
	Dotindex=indexOf(fullfilename,substr2);	
	pref1start=0;
	pref1end=Dotindex;
	pref1=substring(fullfilename,pref1start,pref1end);
	return pref1;
}



//041112 Kota


//041019 Kota: recover the slice number from RAW file name
//060331 solve the problem of underscore containing file name prefix.
//	the prefix is esolved by counting the last position from "." where as the previous version considered the first 
//	underscore as the ending of the prefix.
function returnPerkEl_SliceNum(fullfilename) {
	substr1="_";	
	substr2=".";
	UndScoreindex=indexOf(fullfilename,substr1);
	Dotindex=indexOf(fullfilename,substr2);	
	//pref1start=UndScoreindex+1;	//out 060331
	pref1start=Dotindex-3;
	pref1end=Dotindex;
//	print(Zindex);
//	print(Tindex);
	pref1=substring(fullfilename,pref1start,pref1end);
	return pref1;
}

//041019 Kota: recover frame number from RAW file name 
function returnPerkEl_Thex(fullfilename) {
	substr1="_";	
	substr2=".";
	UndScoreindex=indexOf(fullfilename,substr1);
	Dotindex=indexOf(fullfilename,substr2);
	pref1start=Dotindex+1;
	pref1end=lengthOf(fullfilename);
//	print(Zindex);
//	print(Tindex);
	pref1=substring(fullfilename,pref1start,pref1end);
	return pref1;
}


//	******************************	2. User Interface	******************************	

//Kota: choosing two images among currently opened windows
function twoImageChoice() {
	imgnum=Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("select two images");
	//Dialog.addNumber("number1:", 0);
 	//Dialog.addNumber("number2:", 0);
	Dialog.addChoice("Ch Red", wintitleA);
	Dialog.addChoice("Ch Green", wintitleA);
 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 = Dialog.getNumber();;
 	Gtitle = Dialog.getChoice();
	Rtitle = Dialog.getChoice();
	print(Gtitle + Rtitle);
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
			print(i);
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


//	******************************	3.  PROFILE PLOTTING	******************************

//graph

function K_createThickProfilePlot(pA) {
       K_updatePlotRange(pA);
       Plot.create("Intensity profile", "pixels", "intensity");
       Plot.setLimits(0, pA.length, PlotRange_y_min*0.95, PlotRange_y_max*1.05);
       Plot.setColor("black");
       Plot.add("line", pA);
       Plot.show();
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

// ******************************	4. ARRAYS	******************************

//returns maximum value in the array
function K_retrunArrayMax(anA) {
	aA_max=-500000; //LIB
	for (k=0;k<aA.length;k++) if (aA_max<aA[k]) aA_max=aA[k];
	return aA_max;
 }

function K_retrunArrayMaxPosition(anA) {
	aA_max=-500000; //LIB
	maxpos =0;
	for (k=0;k<aA.length;k++) if (aA_max<aA[k]) {
		aA_max=aA[k];
		maxpos = k;
	}
	return minpos ;
 }


function K_retrunArrayMin(anA) {
	aA_min=500000; //LIB
	for (k=0;k<aA.length;k++) if (aA_min>aA[k]) aA_min=aA[k];
	return aA_min;
 }

//returns minimum position
function K_retrunArrayMinPosition(aA) {
	aA_min=500000; //LIB
	minpos =0;
	for (k=0;k<aA.length;k++) if (aA_min>aA[k]) {
		aA_min=aA[k];
		minpos = k;
	}
	return minpos ;
 }


// sorts both the keyA array and slaveA array in acending order accoriding to keyA
function BubbleSortWithKey(keyA, slaveA) {
	k=keyA.length-1;
	while (k>=0) {
		j=-1;
		for (i=1; i<=k; i++) { 
			if (keyA[i-1] > keyA[i]) {
				j = i-1;
				swap = keyA[j];
				keyA[j] = keyA[i];
				keyA[i] = swap;	

				swap = slaveA[j];
				slaveA[j] = slaveA[i];
				slaveA[i] = swap;
			}
		}
		k = j;
	}
}

macro "test sort" {
	aA = newArray(10, 2, 8, 6, 4);
	bA = newArray(0, 1, 2, 3, 4);
	BubbleSortWithKey(aA, bA);
	print("sorting");
	for (i=0; i<aA.length; i++) print(aA[i]+"    :"+bA[i]);
}



//	******************************	4.5.  Array and Result Table	******************************

// 	printouts array into multiple column.
// 	length of the column is defined by segLength.
// 	prefix of the column tiitle defined by string col_titlepre
function output_MultipleResults(rA, heightA, segLength, col_titlepre) {
	run("Clear Results");
	columnnum=rA.length/segLength;
	for(i = 0; i < columnnum; i++) {
		currentColTitle1="int_"+ col_titlepre+(i+1);
		currentColTitle2="Ycount_"+ col_titlepre+(i+1);
		for(j = 0; j < segLength; j++) {
	            	if (i==0) setResult("x", j, j);
	           		setResult(currentColTitle1, j, rA[i * segLength + j]);
	           		setResult(currentColTitle2, j, heightA[i * segLength + j]);
		}
	}
	updateResults();
}

// 070223 retrieves data from result window and store them in Array
function RetrieveResults(profileA,ylengthA,col_titlepre) {
	x_width = nResults;
	if (x_width != G_w) exit("Results table Missing or Modified");
	ColumnSetNumber=profileA.length/x_width;
	for (i=0; i<ColumnSetNumber; i++) {
		currentColTitle1="int_"+ col_titlepre+(i+1);
		currentColTitle2="Ycount_"+ col_titlepre+(i+1);
		for (j=0; j< x_width; j++) {
	            	//if (i==0) getResult("x", j, j);
	           		profileA[i * x_width + j]=getResult(currentColTitle1, j);
	           		ylengthA[i * x_width + j]=getResult(currentColTitle2, j);			
		}
	}
}


//	******************************	5.  Check states	******************************

function CheckStack() {
	if nSlices(==1) exit("this is not a stack");
}


//	******************************	6.	Math	******************************


function CalcDistance(p1x, p1y, p2x, p2y) {
	sum_difference_squared = pow((p2x - p1x),2) + pow((p2y - p1y),2);
	distance = pow(sum_difference_squared, 0.5);
	return distance;
}

function returnDistance3D(x1, y1, z1, x2, y2, z2){
	dist3D = pow( (pow((x1-x2), 2) + pow((y1-y2), 2) + pow((z1-z2), 2) ), 0.5);
	return dist3D;
}

function returnDistance2D(x1, y1,  x2, y2){
	dist2D = pow( (pow((x1-x2), 2) + pow((y1-y2), 2)  ), 0.5);
	return dist2D;
}

function returnAnglefromLine(){
	getSelectionCoordinates(xCoord, yCoord);

	x1=xCoord[0]; y1=yCoord[0];
	x2=xCoord[1]; y2=yCoord[1];
	x3=xCoord[2]; y3=yCoord[2];

	vx1 = (x1-x2); vy1 = (y1-y2);
	vx2 = (x3-x2); vy2 = (y3-y2);

	scalarProduct=(vx1*vx2 + vy1*vy2);
	lengthProduct =sqrt((pow(vx1, 2)+pow(vy1, 2))) * sqrt((pow(vx2, 2)+pow(vy2, 2)));
	costheta = scalarProduct/lengthProduct ;

	Pi = 3.1415;
	thetadegrees = acos(costheta)*180/Pi;
	print(thetadegrees);
	return thetadegrees
}

//	******************************	7.	Results table	******************************

function DeleteSpecificResults(deleteID){
	labelarrayA = newArray("nucID", "roiX", "roiY", "roiWidth", "roiHeight", 
		"Rsq", "RsqMean", "Sigma", "SigmaMean", 
			"Rsq2", "RsqMean2", "Sigma2", "SigmaMean2" );

	oldN = nResults;
	newN = nResults-1;
	tempA = newArray(newN);
	counter =0;
	for(j=0; j<oldN; j++){
		tempstr=getResultLabel(j)+"\t";
		if(j!=deleteID-1) {
			for(i=0; i<labelarrayA.length; i++) tempstr =tempstr+ getResult(labelarrayA[i], j)+"\t";
			tempA[counter] = tempstr;
			counter++;
			//print(tempstr);
		}
	}
	 run("Clear Results");

	for(j=0; j<newN; j++){
		dataA = split(tempA[j]);
		setResult("Label",j,dataA[0]);
		for(i=0; i<labelarrayA.length; i++) setResult(labelarrayA[i], j, dataA[i+1]);
	}
	updateResults();
}


//	******************************	8.	File IO	******************************

function ProgressReporterWithCheck(path, reporttext){
	
	if (File.exists(path)==0) {
		run("Text Window");
		op = "C:\\temp\\" + File.getName(path);
		saveAs("Text", op);
		run("Close");
	}
	ProgressReporter(path, reporttext);

}

function ProgressReporter(path, reporttext){
	//f = File.open(path);	
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	File.append(month +"-"+dayOfMonth + "\t" + hour + ":" + minute+":" + second +"\t", path);
	File.append("\t"+reporttext +"\n", path);

	//print(f, month +"-"+dayOfMonth + "\t" + hour + ":" + minute+":" + second +"\r");
	//print(f, reporttext);
	//File.close(f);
}

//	******************************	9.	Memory Status	******************************

function CheckMemoryStatus{
	print("Free memory:", call("ij.IJ.freeMemory")); 
	print("current memory:", call("ij.IJ.currentMemory")); 
	print("max memory:", call("ij.IJ.maxMemory"));
	MbmemoryCurrent = parseInt(call("ij.IJ.currentMemory"))/1000000;
	MbmemoryMax = parseInt(call("ij.IJ.maxMemory"))/1000000;
	print("Memory Usage: " + round(MbmemoryCurrent) +" /"+round(MbmemoryMax) + "Mb");
}

//	******************************	10.	Time	******************************

//calculates duration in hour, minutes and seconds. 
//argument s* are starting time, e* are end time
function durationCalc2(shour, sminute, ssecond,ehour, eminute, esecond){
	st = shour * 60 * 60 + sminute * 60 + ssecond;
	et = ehour * 60 * 60 + eminute * 60 + esecond;
	dt = et - st;
	dhour = floor(dt/3600);
	dmin = floor((dt - dhour *60 * 60) / 60 );
	dsec = dt % 60;
	durtext = "duration:" + dhour + ":" + dmin + ":" + dsec;
	return durtext;	 	 
}
