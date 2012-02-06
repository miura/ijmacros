/*
 - remove dots which are too close by (<18 pixels). 
 - duplicate each dot and create a stack, or montage with two channels. 

 fromthis point of TODO, whole code migrated to 
 python code (Dot3Danalysis.py)

 if there is need of migrating python code back to Javascript, then use part of this code
 + newly added functions in python code. 

 Mayumi Isokane +
 Kota Miura (cmci.embl.de) 20101205
*/
// automatic passing of arguments to dialog. 
// reference: Albert's javascript tutorial

importClass(Packages.java.lang.Thread);
importClass(Packages.ij.Macro);
//importClass(Packages.mosaic.core.detection);
importClass(Packages.emblcmci.pt3d.Dot_Detector_3D);
importClass(Packages.ij.plugin.RGBStackMerge);

imp = IJ.getImage();
IJ.run(imp, "Background Subtractor", "length=10 stack");

options = "radius=3 cutoff=0 percentile=0.01";
// Get the current thread
thread = Thread.currentThread();
original_name = thread.getName();

// Rename current thread
thread.setName("Run$_my_batch_process");

// Set the options for the current thread
Macro.setOptions(Thread.currentThread(), options);

pt = IJ.runPlugIn(imp, "emblcmci.pt3d.Dot_Detector_3D", "");

//imp2 = imp.createImagePlus();
impdimA = imp.getDimensions();
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

//there should be a function here, that will check the distance 
NeighborTerminator(xA, yA, zA);

for (var i = 0; i < xA.length; i++){
	IJ.log(xA[i]);
	if (xA[i] > 0) {
		cslice=Math.round(zA[i])+1; //z seems to statrt from 0 in tracker result, so add 1.
		if ((cslice > 0) && (cslice <= nSlices)) {
			ip = imp2.getStack().getProcessor(cslice);
			//ip.setColor(255);
			//ip.drawOval(Math.round(yA[i]), Math.round(xA[i]), 1, 1); //x and y is inverted.
			ip.set(Math.round(yA[i]), Math.round(xA[i]), 255); //x and y is inverted.
		}
	}
}
imp2.show();
merge = new RGBStackMerge();
var stacks = new Array();
stacks[0] = imp2.getImageStack();
stacks[1] = imp.getImageStack();
impmerged = merge.createComposite(imp.getWidth(), imp.getHeight(), imp.getStackSize(), stacks, true);
impmerged.show();

// for getting rid of spots neighboring too close together. 
function NeighborTerminator(xar, yar, zar){
/*	this.xar = xar;
	this.yar = yar;
	this.zar = zar;
*/
	thdist = 18;
	for (var i = 0; i < xar.length; i++){
		cx = xar[i];
		cy = yar[i];
		cz = zar[i];
		if (cx > 0) {		 
			for (var j = 0; j < xar.length; j++){
				if (j != i){
					dist = Math.sqrt( Math.pow((cx - xar[j]), 2) + Math.pow((cy - yar[j]), 2));
					if (dist < thdist){
						IJ.log("Dot" + i + " - Dot"+ j + "too close: dist = " + dist);
						IJ.log(" ---> Dot" + j + " deleted"); 
						xar[j] = -1;
						yar[j] = -1;
						zar[j] = -1; 		
					}
				}
			}
		}
	}
	
}




