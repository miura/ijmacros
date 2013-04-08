'''
Saves a hyperstack as separate series of 2D images. 
Kota Miura
20130408
'''

from ij import IJ
import os

savepath = IJ.getDirectory("")
imp = IJ.getImage()
ssize = imp.getStackSize()
titleext = imp.getTitle()
title = os.path.splitext(titleext)[0]
dimA = imp.getDimensions()
for c in range(dimA[2]):
	for z in range(dimA[3]):
		for t in range(dimA[4]):
			imp.setPosition(c+1, z+1, t+1)
			print c, z, t
			numberedtitle = \
			title + "_c" + IJ.pad(c, 2) + \
			"_z" + IJ.pad(z, 4) + \
			"_t" + IJ.pad(t, 4) + ".tif"
			stackindex = imp.getStackIndex(c, z, t)
			aframe = ImagePlus(numberedtitle, imp.getStack().getProcessor(stackindex))
			IJ.saveAs(aframe, "TIFF", savepath + numberedtitle)
			IJ.log("saved:" + numberedtitle)
	
	