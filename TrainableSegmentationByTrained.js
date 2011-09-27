// Example script for using trainable segmentation
// -- assumes that an extra plugin by Kota is installed
// -- assumes that you already have "trained data" arff
// 20110819
// Kota Miura (miura@embl.de)

// argument = path to the image

//imp = IJ.getImage();
args = getArgument();
argA = Tools.split(args, ":");
IJ.log("source stack: " + argA[0]);
IJ.log("source trained data: " + argA[1]);
filepath = argA[0];
imp = IJ.openImage(filepath);

//path to the arff data
//traindata = "D:\\People\\Tina\\20110813\\data02.arff";
//traindata = "/g/cmci/likun/e1cell1/data.arff";
traindata = argA[1];

importClass(Packages.emblcmci.DotSegmentByTrained);
dbt = new DotSegmentByTrained(traindata, imp);
binimp = dbt.runsilent();
//binimp.show();
newfilename = filepath + ".train.tif"
IJ.saveAs(binimp, "Tiff", newfilename); 