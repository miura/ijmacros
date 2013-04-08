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
for t in range(1, dimA[4] + 1):
	for z in range(1, dimA[3] +1 ):
		for w in range(1, dimA[2] +1 ):
			#imp.setPosition(w+1, z+1, t+1)
			print t, z, w
			numberedtitle = \
			title + "_t" + IJ.pad(t, 4) + \
			"_z" + IJ.pad(z, 4) + \
			"_w" + IJ.pad(w, 4) + ".tif"
			stackindex = imp.getStackIndex(w, z, t)
			aframe = ImagePlus(numberedtitle, imp.getStack().getProcessor(stackindex))
			IJ.saveAs(aframe, "TIFF", savepath + numberedtitle)
			IJ.log("saved: " + str(stackindex) + ", " + numberedtitle)

