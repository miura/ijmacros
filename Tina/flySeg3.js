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
/*
flySeg3.js
input: running averaged and background subtracted images. 
does: FFT, minimum, trainable segmentation using data10.arff 
*/
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

//--- start processing ---
imp = IJ.openImage(fullfilepath);

//--- Bandpass Filtering ----
//op = "filter_large=40 filter_small=2 suppress=None tolerance=5 autoscale saturate";
op = "filter_large=40 filter_small=6 suppress=None tolerance=5";
for(i =1; i <= imp.getStackSize(); i++){
	imp.setSlice(i);
	IJ.run(imp,"Bandpass Filter...", op);
	IJ.log("Band Pass slice: " + i);
}
IJ.run(imp, "Enhance Contrast", "saturated=0.35 normalize normalize_all");
IJ.run(imp, "8-bit", "");
IJ.run(imp,"Minimum...", "radius=1 stack");
IJ.log("band pass and minimum filtering done");

IJ.saveAs(imp, "Tiff", fullfilepath + ".bp.tif");
//--- segmentation using Trained arff data ---
//    arff data should be prepared manually using one of the frame. 

//op = "choose=" + traindata + " choose=" + traindata;
//IJ.run(imp, "Segmentation by Trained Data .aiff", op);
importClass(Packages.emblcmci.DotSegmentByTrained);
dbt = new DotSegmentByTrained(traindata, imp);
binimp = dbt.runsilent();
IJ.log("trained segmentation done");
IJ.saveAs(binimp, "Tiff", fullfilepath + ".bpbin.tif");
binimp.flush();
imp.flush();

