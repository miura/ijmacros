
//080309
//macro "Framewise info Plot Dots in XY and XZ(10x)"{

//to automatically plot all detected dots sequentially
macro PlotAllinDirectory{
	getFileList(directory);
}


function PlotXYXZ(fullpathfile) {
	zscale = 10;
	zslices = 30;//getNumber("zslices?", 30);
	stack4DID=getImageID();
	imw = getWidth();
	op = "group="+zslices+" projection=[Max Intensity]";
	run("Grouped ZProjector", op);
	xyprojID = getImageID();
	rename("zprojection");


	selectImage(stack4DID);
	tnum = nSlices/zslices ;
	newImage("xprojection", "8-bit Black", imw , zslices , tnum);
	xprojID =  getImageID();
	setBatchMode(true);
	xprojectionCore(stack4DID, xprojID , zslices );	//required
	selectImage(xprojID);
	//op = "width="+imw+" height="+Gzscaler*znum;
	op = "width="+imw+" height="+zscale*zslices ;
	run("Size...", op);
	setBatchMode("exit and display");

	selectImage(xyprojID);
	xyname = getTitle();
	//PlotTrackDynamic_stackFrameWiseInfo(xyprojID, "blue", 1);	//required
	PlotTrackDynamic_stackFrameWiseInfoV2(xyprojID, "red", 1, fullpathfile);

	selectImage(xprojID);
	xzname = getTitle();
	//PlotTrackDynamic_stackFrameWiseInfo(xprojID, "blue", zscale );
	PlotTrackDynamic_stackFrameWiseInfo(xprojID, "red", zscale, fullpathfile);

	op = "stack1="+xyname +" stack2="+xzname +" combine";
	run("Stack Combiner", op);
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

//071024
function PlotTrackDynamic_stackFrameWiseInfo(stackID, color, zscale, fullpathfile) {
	selectImage(stackID);
	frames=nSlices;
	fullpathname = fullpathfile;//File.openDialog("Select a track File");
	openedDirectory = File.getParent(fullpathname );
	openedFile = File.getName(fullpathname );
	tempstr = File.openAsString(fullpathname);
	lineA=split(tempstr,"\n");

	currentfA = newArray(lineA.length);
	currentxA = newArray(lineA.length);
	currentyA = newArray(lineA.length);
	currentzA = newArray(lineA.length);

	for (i=0; i<currentfA.length; i++) {
		currentfA[i] = -1;
		currentxA[i] = -1;
		currentyA[i] = -1;
		currentzA[i] = -1;

	}

	if (color=="red") {
		rgb_r=255;
		rgb_g=0;
		rgb_b=0;
	}

	if (color=="blue") {
		rgb_r=0;
		rgb_g=0;
		rgb_b=255;
	}

	if (color=="green") {
		rgb_r=0;
		rgb_g=255;
		rgb_b=0;
	}

	 run("RGB Color");
	setColor(rgb_r,rgb_g,rgb_b);
	//setForegroundColor(rgb_r,rgb_g,rgb_b);		

	for (k=0; k<lineA.length; k++) {
		linecontentA=split(lineA[k],"\t");
		if (linecontentA.length>1) {
			currentfA[k] = parseFloat(linecontentA[0]);
			currentxA[k] = parseFloat(linecontentA[2]);
			currentyA[k] = parseFloat(linecontentA[1]);
			currentzA[k] = parseFloat(linecontentA[3]);

		} else {
			currentfA[k] = -1;
			currentxA[k] = -1;
			currentyA[k] = -1;
			currentzA[k] = -1;

		} 
	}
	wh = getHeight();

	for  (k=0; k<lineA.length; k++) {
		if (currentfA[k]>-1){
			print(""+k+":"+currentfA[k] + ":" + currentxA[k] + "," + currentyA[k] + "," + currentzA[k] );
			setSlice(currentfA[k]+1);
			if (zscale!=1) {
				zposition = wh - ( zscale * (currentzA[k]+1));
				fillOval(currentxA[k]-1, zposition, 3, 3); 	//dots
			} else {
				fillOval(currentxA[k]-1,currentyA[k] -1, 3, 3); 	//dots
			}
		}
	}
	setForegroundColor(255,255,255);

	selectImage(stackID);
}
