
imp = IJ.openImage("/Users/miura/Dropbox/cell1.tif")
IJ.run(imp, "Gaussian Blur...", "sigma=1 stack")
slices = imp.getStackSize()
mont = MontageMaker()
mimp = mont.makeMontage2(imp, 1, slices, 1.0, 1, slices, 1, 0, False) 

#auto threshold method might be different as background size would be 
#variable
IJ.setAutoThreshold(mimp, "Huang dark")	
mint = mimp.getProcessor().getMinThreshold()
maxt = mimp.getProcessor().getMaxThreshold()

mimp.close()
imp.getProcessor().setThreshold(mint, maxt, 0)
IJ.run(imp, "Convert to Mask", " black");
imp.show()