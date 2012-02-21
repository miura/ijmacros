"""
Single frame (the first time frame) ortho view plotting, All points.
File format should be point listings of volocity converted files. 

Converts 4D hyperstack to 3D stack with ortho-views in xy, xz, yz, each with Max projections.
Then points are plotted from all frames to the orthview. 

Requires emblTool.jar package. 

20120220, First Version
Kota Miura (miura@embl.de)
"""
from emblcmci import Extractfrom4D
from emblcmci import XYZMaxProject
from java.util import ArrayList

from ij import IJ
from ij import ImageStack, ImagePlus
from java.util import ArrayList
from util.opencsv import CSVReader
from java.io import FileReader
from java.awt import Color

import os

def readCSV(filepath):
   reader = CSVReader(FileReader(filepath), ",")
   ls = reader.readAll()
   data = ArrayList()
   for item in ls:
   	  data.add(item)
   return data

# extracting stack time frames and convert to ortho

#20hr original
#filepath= 'C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfull.csv'
#20hr
#filepath = 'C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfull_corrected.csv'
#23hr
#filepath = 'C:/dropbox/My Dropbox/Mette/23h_/23hdatacut0_3dshifted.csv'
#27hr
filepath = 'C:/dropbox/My Dropbox/Mette/27h/data27_cut0_corrected.csv'

imp = IJ.getImage()
e4d = Extractfrom4D()
e4d.setGstarttimepoint(1)
IJ.log("current time point" + str(1))
aframe = e4d.coreheadless(imp, 3)
ortho = XYZMaxProject(aframe)
orthoimp = ortho.getXYZProject()
out = orthoimp
#out.setCalibration(imp.getCalibration().copy())

IJ.run(out, "Grays", "");
IJ.run(out, "RGB Color", "");

# load data from file
filename = os.path.basename(filepath)
newfilename = os.path.join(os.path.splitext(filename)[0], '_plot.tif')

PLOT_ONLY_IN_FRAME1 = False
data = readCSV(filepath)
calib = imp.getCalibration()
xscale = calib.pixelWidth
yscale = calib.pixelHeight
zscale = calib.pixelDepth
cred = Color(255, 0, 0)
cblue = Color(0, 0, 255)
xoffset = imp.getWidth()
yoffset = imp.getHeight()
ip = out.getProcessor()

size = 5
off = int(Math.floor(size/2) + 1)
for i in range(len(data)):
	if i < 1:
		continue
#	if i > 20:
#		break
	frame = float(data.get(i)[2])
#	nextframe = float(data.get(i+1)[2])
#	if nextframe - frame < 1:
#		print str(i), 'trackend'
#	else:
		#print str(i), 'in track'
	x1 = int(round(float(data.get(i)[13]) / xscale))
	y1 = int(round(float(data.get(i)[14]) / xscale))
	z1 = int(round(float(data.get(i)[15]) / xscale))
	ip.setColor(Color(255, 100, 100))
	ip.drawOval(x1-off, y1-off, size, size)
	ip.drawOval(x1-off, yoffset + z1 -off, size, size)
	ip.drawOval(xoffset + z1 -off, y1 - off, size, size)		
# plot 
outimp = ImagePlus(os.path.basename(filename)+'_Out.tif', ip)
outimp.show()




