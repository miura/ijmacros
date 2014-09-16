'''
Tiff file resolution checker
'''

from ij.io import TiffDecoder
from ij.io import DirectoryChooser
from ij import IJ
import os

def xresGetter(d, filename):
	td = TiffDecoder(d, filename)
	imginfoA = td.getTiffInfo()
	#print len(imginfoA)
	#for imginfo in imginfoA:
	#	print "pixelWidth", imginfo.pixelWidth
	return imginfoA[0].pixelWidth
	
srcDir = DirectoryChooser("Choose Tiff Series Folder").getDirectory() 
IJ.log("directory: "+ srcDir)

for root, directories, filenames in os.walk(srcDir):
	filenames = sorted(filenames)
	for filename in filenames:
		if not filename.endswith(".tif"):
			continue
		#IJ.log(filename)
		IJ.log(filename + ":\t" + "pixelWidth=" + str(xresGetter(srcDir, filename)))
         