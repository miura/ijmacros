//Gaussian Blurr and save as
filepath = "/g/cmci/mette/s1.tif" 
imp = IJ.openImage(filepath);
IJ.run(imp, "Gaussian Blur...", "sigma=1 stack");
IJ.saveAs(imp, "tiff", filepath + "_gb1.tif");
