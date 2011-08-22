// Example script for using trainable segmentation
// -- assumes that an extra plugin by Kota is installed
// -- assumes that you already have "trained data" arff
// 20110819
// Kota Miura (miura@embl.de)

// get currently active image / image stack
imp = IJ.getImage();

//path to the arff data
traindata = "D:\\People\\Tina\\20110813\\data02.arff";

importClass(Packages.emblcmci.DotSegmentByTrained);
dbt = new DotSegmentByTrained(traindata, imp);
binimp = dbt.runsilent();
binimp.show();