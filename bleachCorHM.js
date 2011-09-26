/*
Bleach Correction by histogram matching. 
requires CorrectBleach plugin installed. 

Kota Miura
20110909
*/

importClass(Packages.emblcmci.BleachCorrection_MH);

args = getArgument();
filepath = args;
imp = IJ.openImage(filepath);
impdup = new Duplicator().run(imp);
newfilename = filepath + "c.tif";
bc = new BleachCorrection_MH(impdup);
bc.doCorrection();
IJ.saveAs(impdup, "Tiff", newfilename); 