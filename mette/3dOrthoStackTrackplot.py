"""
Single frame plotting, All tracks.

Converts 4D hyperstack to 3D stack with ortho-views in xy, xz, yz, each with Max projections.
Then 2D tracks are plotted.

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

filepath = 'C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfull_corrected_1_6_6.csv'
imp = IJ.getImage()
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
#ip = out.getStack().getProcessor(1)

for i in range(len(data)-1):
	if i < 1:
		continue
#	if i > 20:
#		break
	frame = float(data.get(i)[2])
	nextframe = float(data.get(i+1)[2])
	if nextframe - frame < 1:
		print str(i), 'trackend'
	else:
		frame = int(frame)
		print str(frame+1), '...plotting'
		ip = out.getStack().getProcessor(frame + 1) 
		x1 = int(round(float(data.get(i)[6]) / xscale))
		y1 = int(round(float(data.get(i)[7]) / xscale))
		z1 = int(round(float(data.get(i)[8]) / xscale))
		x2 = int(round(float(data.get(i+1)[6]) / xscale))
		y2 = int(round(float(data.get(i+1)[7]) / xscale))
		z2 = int(round(float(data.get(i+1)[8]) / xscale))	
		ip.setLineWidth(1)
		ip.setColor(Color(255, 100, 100))
		ip.drawLine(x1, y1, x2, y2)
		ip.drawLine(x1, yoffset+ z1, x2, yoffset+z2)
		ip.drawLine(xoffset+z1, y1, xoffset+z2, y2)
		

#for d in data:
#   frame = int(d[1])
#   direction = float(d[8])
#   if direction <= 0:
#      
#   else:
#      ip.setColor(Color(100, 100, 255))
#out.updateAndDraw()

# plot 
#outimp = ImagePlus(os.path.basename(filename)+'_Out.tif', ip)
#outimp.show()
out.show()




