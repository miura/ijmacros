/* K_substackExtractor.ijm
 * originally was in ManualTrack3.txt (20050119)
 * 
 * should be converted that it cuold be used by importing textfile. 
 * 
 * Kota Miura (miura@embl.de)
 */
function substack_samplingCore(RoiID,stackID) {
	selectImage(stackID);
	frames=nSlices;
	ROIsize=6;
	startframe=Return_ROI_startf(RoiID);
	endframe=Return_ROI_endf(RoiID);
	coordArraysize=endframe-startframe+1;
	resxA=newArray(coordArraysize);
	resyA=newArray(coordArraysize);
	reszA=newArray(coordArraysize);
	restoreCoordArray2D(RoiID,resxA,resyA,reszA);

	op="name=subSTK_cell"+RoiID+" type=8-bit fill=White width=" + ROIsize + " height=" + ROIsize + " slices="+coordArraysize;
	run("New...", op);
	subID=getImageID();	

	for(i=0;i<resxA.length;i++) {
		selectImage(stackID);	
		op="slice="+reszA[i];
		run("Set Slice...", op);
		makeRectangle((resxA[i]-(ROIsize/2)), (resyA[i]-(ROIsize/2)), ROIsize, ROIsize);
		run("Copy");
		selectImage(subID);	
		op="slice="+(i+1);
		run("Set Slice...", op);
		run("Paste");
	}
}

macro "Generate Substack" {
	RoiID=getNumber("RoiID?",1);
	stackID=getImageID();
	substack_samplingCore(RoiID,stackID);
}
