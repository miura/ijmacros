/*
* script for creating a stack with same size of the current stack, and plot xyz dots listed in results window.\
*
* Kota Miura
*/

imp = IJ.getImage();
impdimA = imp.getDimensions();


pt = IJ.runPlugIn(imp, "mosaic.plugins.ParticleTracker3DModular_", "radius=3 cutoff=3 percentile=0.01 link=2 displacement=10");
pt.transferParticlesToResultsTable();

//imp2 = imp.createImagePlus();
ims = imp.createEmptyStack();
for (var i = 0; i < impdimA[3]; i++) 
	ims.addSlice(i, new ByteProcessor(impdimA[0], impdimA[1]));
imp2 = new ImagePlus("test", ims);

nSlices = imp2.getNSlices();

rt = ResultsTable.getResultsTable();
xindex = rt.getColumnIndex("x"); 
yindex = rt.getColumnIndex("y"); 
zindex = rt.getColumnIndex("z");
xA = rt.getColumn(xindex);
yA = rt.getColumn(yindex);
zA = rt.getColumn(zindex);
for (var i = 0; i < xA.length; i++){
	IJ.log(xA[i]);
	cslice=Math.round(zA[i])+1; //z seems to statrt from 0 in tracker result, so add 1.
	if ((cslice > 0) && (cslice <= nSlices)) {
		ip = imp2.getStack().getProcessor(cslice);
		//ip.setColor(255);
		//ip.drawOval(Math.round(yA[i]), Math.round(xA[i]), 1, 1); //x and y is inverted.
		ip.set(Math.round(yA[i]), Math.round(xA[i]), 255); //x and y is inverted.

	}
}
imp2.show();
