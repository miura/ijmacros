/* 3D-t analysis
Kota Miura (miura at embl de)
0710 Made with the Tomo Kitajima@Ellenberg project (kinetochore tracking)
071102 modifed XY corrector
*/


var Gzscaler=1;

// use with xyzt stack, to generate both x- and z- projection stacks (max intensity) 
macro "z nd x-projection combiner" {
	zslices = getNumber("How many z-slices?", 15);
	xzprojector(zslices); 
}

function xzprojector(znum){
	imw = getWidth();
	imh = getHeight();
	//znum = 15;
	tnum = nSlices/znum;
	originalID = getImageID();
	op = "group="+znum+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	zprojID = getImageID();
	rename("zprojection");
	setBatchMode(true); 

	newImage("xprojection", "8-bit White", imw, znum, tnum);
	xprojID =  getImageID();
	xprojName = getTitle();

	 xprojectionCore(originalID, xprojID , znum);

	selectImage(xprojID );	
	op = "width="+imw+" height="+Gzscaler*znum;
	run("Size...", op);
	op = "stack1="+xprojName+" stack2=zprojection combine";
	run("Stack Combiner", op);
	setBatchMode("exit and display");
}

//works only with height 512
macro "x-projection" {
	imw = getWidth();
	imh = getHeight();
	znum = getNumber("z slices?", 15);
	//znum = 15;
	tnum = nSlices/znum;
	originalID = getImageID();
	newImage("xprojection", "8-bit Black", imw, znum, tnum);
	xprojID =  getImageID();
	setBatchMode(true);
	xprojectionCore(originalID, xprojID , znum);
	selectImage(xprojID);
	op = "width="+imw+" height="+Gzscaler*znum;
	run("Size...", op);
	setBatchMode("exit and display");
	 
}

//slice 1 comes at the bottom of the xz plane. 
function xprojectionCore(originalID, xprojID , znum) {
	selectImage(originalID);
	imw = getWidth();
	imh = getHeight();
	tnum = nSlices/znum;
	newImage("temp_timepoint", "8-bit White", imw, imh, znum);
	tempimgID = getImageID();

	for(j=0; j<tnum; j++) {
		for(i=0; i<znum; i++) {
			selectImage(originalID);
			setSlice(j * znum + i + 1);
			run("Select All");
			run("Copy");
			selectImage(tempimgID);
			setSlice(i + 1);
			run("Paste");				
		}
		selectImage(tempimgID);
		run("3D Project...", 
			"projection=[Brightest Point] axis=X-Axis slice=1 initial=90 total=1 rotation=1 lower=1 upper=255 opacity=0 surface=100 interior=50");

		setSlice(1);
		sliceypos = imh/2 + 1 - floor(znum/2);
		makeRectangle(0, sliceypos, imh, znum);
		run("Copy");
		close();
		selectImage(xprojID );	
		setSlice(j+1);
		run("Paste");
	}	
	selectImage(tempimgID);	
	close();
}

//works with xyz-t sequence. maximum projection of each xy plane along t, and then create a 3D stack. (xy tprojeciton + z)
//071031  if the particles are color coded, then t-projected image LUT could be adjusted for different colors.
macro "t-Projection" {
	znum = getNumber("Z slices?", 15);
	originalID = getImageID();
	if (((nSlices/znum) - floor(nSlices/znum)) !=0) exit("wrong stack??");
	tnum = 	nSlices/znum;
	imw = getWidth();
	imh = getHeight();
	newImage("temp", "8-bit White", imw, imh, tnum);
	tempstackID = getImageID();
	newImage("xy-t-projection", "8-bit White", imw, imh, znum);
	outstackID = getImageID();
	setBatchMode(true);
	for(i = 0; i<znum; i++) {
		for(j = 0; j<tnum; j++) {
			selectImage(originalID);
			setSlice(znum*j + i+1);
			run("Copy");
			selectImage(tempstackID);
			setSlice(j + 1);
			run("Paste");
		}
		op = "start=1 stop="+tnum+" projection=[Max Intensity]";
		run("Z Project...", op);
		run("Copy");
		close();
		selectImage(outstackID);
		setSlice(i + 1);
		run("Paste");
	}
	selectImage(tempstackID);	
	close();
	setBatchMode("exit and display");
}

//run("3D Project...", "projection=[Brightest Point] axis=X-Axis slice=15 initial=0 total=360 rotation=5 lower=1 upper=255 opacity=0 surface=0 interior=70");

macro "-"{}

//correct the xy shifting of xyz-t stack. 
macro "xy systematic fluctuation corrector"{
	znum=15;
	originalID = getImageID();
	if (((nSlices/znum) - floor(nSlices/znum)) !=0) exit("wrong stack??");
	thlow = getNumber("threshold low?", 45); //45; // threshold lower value for the initial particle detection. (particles larger than 50 pixels area)
	print(((nSlices/znum) - floor(nSlices/znum)));
	op = "group="+znum+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	zprojID = getImageID();
	xycorrector(originalID, zprojID, znum, thlow);
}

function xycorrector(originalID, zprojID, znum, thlow){
	setBatchMode(true);
	selectImage(zprojID);
	imw = getWidth();
	imh = getHeight();
 	tnum = nSlices;
	//setAutoThreshold();
	setThreshold(thlow, 255);		//lower threshold value is better
	run("Set Measurements...", "area mean centroid center integrated slice redirect=None decimal=1");
	run("Analyze Particles...", "size=50-Infinity circularity=0.00-1.00 show=Outlines display exclude clear stack");
	slicenA= newArray(nResults);
	xA= newArray(nResults);
	yA= newArray(nResults);
	particlecountA = newArray(tnum );
	xaveA= newArray(tnum );
	yaveA= newArray(tnum );
	xshiftA= newArray(tnum );
	yshiftA= newArray(tnum );
	for (i = 0; i<nResults; i++) {
		slicenA[i] = getResult("Slice", i);
		xA[i] = getResult("XM", i);
		yA[i] = getResult("YM", i);
	}
	for (i = 0; i<slicenA.length; i++) {
		xaveA[slicenA[i]-1] += xA[i];			
		yaveA[slicenA[i]-1] += yA[i];
		particlecountA[slicenA[i]-1] +=1; 			
	}
	for (i = 0; i<particlecountA.length; i++) {
		xaveA[i] /=particlecountA[i];
		yaveA[i] /=particlecountA[i];
	}
	for (i = 0; i<xshiftA.length; i++) {
		if (i==0) {
			xshiftA[i] =0;
			yshiftA[i] =0;
		} else {
			xshiftA[i] = xaveA[i] - xaveA[i-1]+xshiftA[i-1];
			yshiftA[i] = yaveA[i] - yaveA[i-1]+yshiftA[i-1];
//			xshiftA[i] = xaveA[i] - xaveA[0];
//			yshiftA[i] = yaveA[i] - yaveA[0];
		}
		print("t:" + i + " x:" + xshiftA[i] + " y:"+yshiftA[i]);
	}
	newImage("xycorrectedZproj", "8-bit Black", imw, imh, tnum);
	zproCorjID = getImageID;	
	for(i=0; i<tnum;i++) {
		selectImage(zprojID);		
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(zproCorjID);	
		setSlice(i+1);
		makeRectangle(-1*xshiftA[i], -1*yshiftA[i], imw, imh);
		run("Paste");
	}	
	newImage("xycorrected", "8-bit Black", imw, imh, tnum*znum);
	xycorID=getImageID();
	for(i=0; i<tnum;i++) {
		for(j=0; j<znum;j++) {
			selectImage(originalID);
			setSlice(i*znum+j+1);
			run("Select All");
			run("Copy");			
			selectImage(xycorID);
			setSlice(i*znum+j+1);
			makeRectangle(-1*xshiftA[i], -1*yshiftA[i], imw, imh);
			run("Paste");	
		}
	}
	setBatchMode("exit and display");
}



macro "test z shifting" {
	tnum = nSlices; 
	yshiftA= newArray(tnum );
	Zshiftdetector(yshiftA);		//absolute z position at frame i - absolute position at frame 0
//	Zshiftdetector2(yshiftA);
//	for(i=0; i<yshiftA.length; i++)	print("t:" + i + "zshift:"+round(yshiftA[i]/10));
	for(i=0; i<yshiftA.length; i++)	print("t:\t" + i + "\tzshift:\t"+yshiftA[i]);
}

/
//corrects systematic z axis shifting. 
//its wroking, but not so effective. 
macro "z systematic fluctuation correector" {
	imw = getWidth();
	imh = getHeight();
	//znum = 15;
	znum = getNumber("z slices?", 15);
	zshiftthreshold = 0.5;				 //threshold for shifting. can be varied. 
	thlow = getNumber("threshold low?", 17); 

	tnum = nSlices/znum;
	originalID = getImageID();
	newImage("xprojection", "8-bit Black", imw, znum, tnum);
	xprojID =  getImageID();
	setBatchMode(true);
	xprojectionCore(originalID, xprojID , znum);
	selectImage(xprojID);
	op = "width="+imw+" height="+Gzscaler*znum;
	run("Size...", op);
	setBatchMode("exit and display");
	//setAutoThreshold();
	setThreshold(thlow, 255);
	yshiftA= newArray(tnum );
	Zshiftdetector(yshiftA);
	//Zshiftdetector2(yshiftA);
	for(i=0; i<yshiftA.length; i++) {	
		print("t:" + i + "zshift:"+yshiftA[i]);
	}
	zmax = K_retrunArrayMax(yshiftA);
	zmin = K_retrunArrayMin(yshiftA);
	range = zmax -zmin;
	range = (floor(range/Gzscaler)+1) * Gzscaler;			//to make it scaleable with Gzscaler	
	print("zmin"+zmin+" zmax"+zmax+"range"+range);
	newImage("z-shifted", "8-bit Black", imw, znum*Gzscaler+range, tnum);
	zcorrectedXprojID = getImageID();

	yshiftaroundA= newArray(yshiftA.length);
	for (i=0; i< yshiftaroundA.length; i++) {
		tempresidue = yshiftA[i] - floor(yshiftA[i]);
		if (abs(tempresidue) > zshiftthreshold ) {	
			yshiftaroundA[i] = round(yshiftA[i]);
		} else {
			if (yshiftA[i] >=0)
				yshiftaroundA[i] = floor(yshiftA[i]);
			else
				yshiftaroundA[i] = floor(yshiftA[i])+1;
		}			
	}	
	zmaxstack = K_retrunArrayMax(yshiftaroundA);
	zminstack = K_retrunArrayMin(yshiftaroundA);
	newzslices = znum + zmaxstack - zminstack;
	print("zminstack"+zminstack +" zmaxstack"+zmaxstack +"newslices"+newzslices );
	setBatchMode(true);
	for (i=0; i<tnum; i++) {
		selectImage(xprojID);		
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(zcorrectedXprojID);	
		setSlice(i+1);
		makeRectangle(0, -1*zmin-yshiftaroundA[i], imw, znum*Gzscaler);
		run("Paste");
		print("t:" + i + "  zshift:"+yshiftA[i] + " approximated to "+ yshiftaroundA[i]);
	}
	setBatchMode("exit and display");
	print("New Slice Number: "+newzslices);
	newImage("z-shiftedStack", "8-bit Black", imw, imh,newzslices*tnum);
	zcorrectedStackID = getImageID();
	setBatchMode(true);
	for (i=0; i<tnum; i++) {
		for (j=0; j<znum; j++) {
			selectImage(originalID);
			setSlice(i*znum+j+1);
			run("Select All");
			run("Copy");
			selectImage(zcorrectedStackID);		
			setSlice(i*newzslices+j+1+yshiftaroundA[i]);
			run("Paste");			
		}
		if (abs(yshiftaroundA[i])>0) {
			print("timepoint:"+i+" shifted"+yshiftaroundA[i]);
		}
	}
	setBatchMode("exit and display");
}


macro "test round" {
	print(round(-0.8));
	print(round(0.8));
	print(floor(-0.8));
	print(floor(-0.2));


}

function K_retrunArrayMax(aA) {
	aA_max=-500000; //LIB
	for (k=0;k<aA.length;k++) if (aA_max<aA[k]) aA_max=aA[k];
	return aA_max;
 }

function K_retrunArrayMin(aA) {
	aA_min=500000; //LIB
	for (k=0;k<aA.length;k++) if (aA_min>aA[k]) aA_min=aA[k];
	return aA_min;
 }


// by particle analysis
function Zshiftdetector(yshiftA) {
	minparticlesize = 20;
	tnum = nSlices;
	run("Set Measurements...", "area mean centroid center integrated slice redirect=None decimal=1");
//	op = "size="+minparticlesize +"-Infinity circularity=0.00-1.00 show=Outlines display exclude clear stack";
	op = "size="+minparticlesize +"-Infinity circularity=0.00-1.00 show=Outlines display clear stack";
	run("Analyze Particles...", op);
	slicenA= newArray(nResults);
	xA= newArray(nResults);
	yA= newArray(nResults);
	particlecountA = newArray(tnum );
	xaveA= newArray(tnum );
	yaveA= newArray(tnum );
	xshiftA= newArray(tnum );
	//yshiftA= newArray(tnum );
	for (i = 0; i<nResults; i++) {
		slicenA[i] = getResult("Slice", i);
		xA[i] = getResult("XM", i);
		yA[i] = getResult("YM", i);
	}
	for (i = 0; i<slicenA.length; i++) {
		xaveA[slicenA[i]-1] += xA[i];			
		yaveA[slicenA[i]-1] += yA[i];
		particlecountA[slicenA[i]-1] +=1; 			
	}
	for (i = 0; i<particlecountA.length; i++) {
		xaveA[i] /=particlecountA[i];
		yaveA[i] /=particlecountA[i];
	}
	for (i = 0; i<xshiftA.length; i++) {
		xshiftA[i] = xaveA[i] - xaveA[0];
		yshiftA[i] = yaveA[i] - yaveA[0];
		print("t:\t" + i + "\t z:\t"+yaveA[i]+"\t");
	}
}

// by measuring the centre of mass of the thresholded. 
function Zshiftdetector2(yshiftA) {
	tnum = nSlices;
	//run("Set Measurements...", "area mean centroid center integrated slice redirect=None decimal=1");
	run("Set Measurements...", "area mean centroid center integrated slice limit redirect=None decimal=1");
	run("Clear Results");
	for (i=0; i<tnum; i++) {
		setSlice(i+1);
		run("Measure");
	}
	xaveA= newArray(tnum );
	yaveA= newArray(tnum );
	xshiftA= newArray(tnum );
	//yshiftA= newArray(tnum );
	for (i = 0; i<xaveA.length; i++) {
		xaveA[i] = getResult("XM", i);			
		yaveA[i] = getResult("YM", i);;
	}
	for (i = 0; i<xshiftA.length; i++) {
		if (i>0) {
			xshiftA[i] = xaveA[i] - xaveA[i-1]+xshiftA[i-1];
			yshiftA[i] = yaveA[i] - yaveA[i-1]+yshiftA[i-1];
		} else {	 //i=0
			xshiftA[i] = 0;
			yshiftA[i] = 0;
		}
		print("t:\t" + i + "\t x:\t" + xshiftA[i] + "\ty:\t"+yshiftA[i]+"\t");
	}
}

macro "-"{}
// 3D filters for stacks
// following plugins must be installed:
// 3D median filter
macro "3Dt median filter" {
	filters3D(1);
}
/*
macro "3Dt mean filter" {
	filters3D(2);
}
macro "3Dt Morpho Binary" {
	filters3D(3);
}
macro "3Dt Morpho Gray" {
	filters3D(4);
}
*/
macro "3Dt TopHat filter" {
	filters3D(5);
}

funciton filters3D(filtertype){
	imw = getWidth();
	imh = getHeight();
	znum=15;
	tnum = nSlices/znum;
	orgID = getImageID();
	filterXYsigma = getNumber("filter radius XY?", 2);
	filterZsigma = 	getNumber("filter radius Z?", 1);

	newImage("tmpz", "8-bit Black", imw, imh, znum);
	tempzID = getImageID();
	newImage("Median3Dprocessed", "8-bit Black", imw, imh, znum*tnum);
	med3DID = getImageID();
	opstr = "radius_xy="+filterXYsigma +" radius_z="+filterZsigma;
	for(i = 0; i<tnum; i++) {
		for(j = 0; j<znum; j++) {
			selectImage(orgID);
			setSlice(i*znum+j+1);
			run("Select All");
			run("Copy");
			selectImage(tempzID);
			setSlice(j+1);
			run("Paste");
		}
		selectImage(tempzID);
		if (filtertype==1) {
			run("3D Median Filter", opstr);
			selectImage("3D Median");
		}
		if (filtertype==2) run("3D Mean Filter", opstr);
		if (filtertype==3) run("3D Morpho Binary", opstr);
		if (filtertype==4) run("3D Morpho Gray", opstr);
		if (filtertype==5) {
			run("3D TopHat Filter", opstr);
			selectImage("3D tophat");
		}
		temp3DmedID=getImageID();
		for(j = 0; j<znum; j++) {
			selectImage(temp3DmedID);
			setSlice(j+1);
			run("Select All");
			run("Copy");
			selectImage(med3DID );
			setSlice(i*znum+j+1);
			run("Paste");
		}
		selectImage(temp3DmedID); close();
	}
	selectImage(tempzID); 
	close();
}

//**********************
