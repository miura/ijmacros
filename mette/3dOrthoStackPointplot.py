"""
Stack ortho view plotting, All points.
File format should be point listings of volocity converted files. 
tracks willl also plotted over the points, to evaluate the tracking results. 
For turining this second plotting on/off, comment out /decomment 'addStackTracks'

Converts 4D hyperstack to 3D stack with ortho-views in xy, xz, yz, each with Max projections.
Then points are plotted.

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

"""
creates orthoview stack from 4D hyperstack. 
"""
def orthoStackFrom4D(imp):
	stkA = ArrayList()
	for i in range(1, imp.getNFrames()+1):
	   e4d = Extractfrom4D()
	   e4d.setGstarttimepoint(i)
	   IJ.log("current time point" + str(i))
	   aframe = e4d.coreheadless(imp, 3)
	   ortho = XYZMaxProject(aframe)
	   orthoimp = ortho.getXYZProject()
	   stkA.add(orthoimp)
	   #orthoimp.show()
	stk = ImageStack(stkA.get(0).getWidth(), stkA.get(0).getHeight())
	for item in stkA:
   		stk.addSlice("slcie", item.getProcessor())
	out = ImagePlus("out", stk)
	return out
	
# core part of the Add3DOrthoStackTrackplot.py
def addStackTracks(outimp, data, xoffset, yoffset, xscale):
	size = 3
	off = int(Math.floor(size/2) + 1)
	for i in range(len(data)):
		if i < 2:
			continue
#	if i > 20:
#		break
		frame = float(data.get(i)[2])
		preframe = float(data.get(i-1)[2])
		if frame + 1 > outimp.getStackSize():
			continue
		if frame - preframe >= 1:
			frame = int(frame)
			#print str(frame+1), '...plotting'
			ip = outimp.getStack().getProcessor(frame + 1) 
			x1 = int(round(float(data.get(i-1)[6]) / xscale))
			y1 = int(round(float(data.get(i-1)[7]) / xscale))
			z1 = int(round(float(data.get(i-1)[8]) / xscale))
			x2 = int(round(float(data.get(i)[6]) / xscale))
			y2 = int(round(float(data.get(i)[7]) / xscale))
			z2 = int(round(float(data.get(i)[8]) / xscale))	
			ip.setLineWidth(1)
			ip.setColor(Color(100, 100, 255))
			ip.drawLine(x1, y1, x2, y2)
			ip.drawLine(x1, yoffset+ z1, x2, yoffset+z2)
			ip.drawLine(xoffset+z1, y1, xoffset+z2, y2)
			ip.drawLine(xoffset+z1, y1, xoffset+z2, y2)
			ip.setColor(Color(100, 100, 255))		
			ip.drawOval(x1-off, y1-off, size, size)
			ip.drawOval(x1-off, yoffset + z1 -off, size, size)
			ip.drawOval(xoffset + z1 -off, y1 - off, size, size)   

# extracting stack time frames and convert to ortho
#20hr original
#filepath= 'C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfull.csv'

#20hr corrected
#filepath = 'C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfull_corrected.csv'
#trackfilepath = 'C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfull_corrected_1_6_6.csv'
#23hr corrected
#filepath = 'C:/dropbox/My Dropbox/Mette/23h_/23hdatacut0_3dshifted.csv'
#trackfilepath = 'C:/dropbox/My Dropbox/Mette/23h_/23hdatacut0_3dshifted_1_6_6.csv'
#27hr corrected
filepath = 'C:/dropbox/My Dropbox/Mette/27h/data27_cut0_corrected.csv'
trackfilepath = 'C:/dropbox/My Dropbox/Mette/27h/data27_cut0_corrected_1_6_6.csv'

imp = IJ.getImage()
out = orthoStackFrom4D(imp)
#out.show()

IJ.run(out, "Grays", "");
IJ.run(out, "RGB Color", "");
out.setCalibration(imp.getCalibration().copy())

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
size = 5
off = int(Math.floor(size/2) + 1)
for i in range(len(data)):
	if i < 1:
		continue
#	if i > 20:
#		break
	frame = float(data.get(i)[2])
	frame = int(frame)
#	print str(frame+1), '...plotting'
	if frame > out.getStackSize():
		continue
	ip = out.getStack().getProcessor(frame) 
	x1 = int(round(float(data.get(i)[13]) / xscale))
	y1 = int(round(float(data.get(i)[14]) / xscale))
	z1 = int(round(float(data.get(i)[15]) / xscale))
	ip.setColor(Color(255, 100, 100))
	ip.drawOval(x1-off, y1-off, size, size)
	ip.drawOval(x1-off, yoffset + z1 -off, size, size)
	ip.drawOval(xoffset + z1 -off, y1 - off, size, size)	
# plot 
#outimp = ImagePlus(os.path.basename(filename)+'_Out.tif', ip)
#outimp.show()

trackdata = readCSV(trackfilepath)
addStackTracks(out, trackdata, xoffset, yoffset, xscale)

out.show()




