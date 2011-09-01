// Kota Miura (miura@embl.de)
// for segmenting fly epidermis
// Initial Version: 20110822
// requirements
//	walking average plugin
//	stack trained segmentation plugin
// this code is optimized for headless processing. 
// for this, there are seemingly unrequired loops for stack processing. 
// this might cause problem if you run it on desktop. 
// *** usage excample in cluster ***
// fiji --headless -batch /g/almf/miura/Tina/flySegmentor.js <imagestack.tif>:<trainingdata.aiff>

//--- get commandline arguments ---
args = getArgument();
importClass(Packages.ij.util.Tools);
argA = Tools.split(args, ":");
IJ.log("source stack: " + argA[0]);
IJ.log("source trained data: " + argA[1]);

//--- split file path argument, extract the file name ---
fpA = Tools.split(argA[0], "/");
path = "/";
for (i in fpA){
	if (i != (fpA.length - 1))
		path = path + fpA[i] + "/";
	else
		file = fpA[i];
}
traindata =argA[1];

//--- prepare file name for saving output ---
fullfilepath = path + file;
fullsavepath = fullfilepath+".proc.tif";

//--- start processing ---
imp = IJ.openImage(fullfilepath);

//--- running (walking) average of stack ---
//    this requires plugin "running Z projector"
IJ.run(imp, "Running ZProjector", "running=3 projection=[Average Intensity]");
aveimp = IJ.getImage();
imp.flush();
imp = aveimp.duplicate();
aveimp.flush();
IJ.log("walking average done: total slices " + imp.getStackSize());
IJ.saveAs(imp, "Tiff", fullsavepath+".aftRun.tif");

//--- background removal using blurred image stack ---
blurrimp = imp.duplicate();
for (i = 1; i <= blurrimp.getStackSize(); i++){
	blurrimp.setSlice(i);
	IJ.run(blurrimp, "Gaussian Blur...", "sigma=15 stack");
}	
ic = new ImageCalculator();
for (i=1; i<=imp.getStackSize(); i++){
	imp.setSlice(i);
	blurrimp.setSlice(i);
	ic.run("Subtract", imp, blurrimp);
}
//ic.run("Subtract stack", imp, blurrimp);
blurrimp.flush();
IJ.log("backsub done: total slices " + imp.getStackSize());
IJ.saveAs(imp, "Tiff", fullsavepath+".aftsub.tif");

//--- Bandpass Filtering ----
for(i =1; i <= imp.getStackSize(); i++){
	imp.setSlice(i);
	IJ.run(imp,"Bandpass Filter...", "filter_large=40 filter_small=6 suppress=None tolerance=5 autoscale saturate");
	IJ.log("Band Pass slice: " + i);
}
IJ.run(imp,"Enhance Contrast", "saturated=0.35");
IJ.run(imp, "8-bit", "");	
IJ.run(imp,"Minimum...", "radius=1 stack");
IJ.log("band pass and minimum filtering done");

//--- segmentation using Trained arff data ---
//    arff data should be prepared manually using one of the frame. 

//op = "choose=" + traindata + " choose=" + traindata;
//IJ.run(imp, "Segmentation by Trained Data .aiff", op);
importClass(Packages.emblcmci.DotSegmentByTrained);
dbt = new DotSegmentByTrained(traindata, imp);
binimp = dbt.runsilent();
IJ.log("trained segmentation done");
IJ.saveAs(binimp, "Tiff", fullsavepath);
IJ.saveAs(imp, "Tiff", fullsavepath + ".noseg.tif");
binimp.flush();
imp.flush();

