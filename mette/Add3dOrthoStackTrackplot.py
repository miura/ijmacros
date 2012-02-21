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

#20hr original
#filepath = 'C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfull_1_6_6.csv'
#20hr corrected
filepath ='C:/dropbox/My Dropbox/Mette/20_23h/20_23hrfullDriftCor_Track1_6_1.csv'

imp = IJ.getImage()
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

# this part should be somehow rewritten, not directly giving the size
xoffset = 512 #imp.getWidth()
yoffset = 512 #imp.getHeight()
#ip = out.getStack().getProcessor(1)

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
		if frame - preframe < 1:
			print str(i), 'trackend'
		else:
			frame = int(frame)
			print str(frame+1), '...plotting'
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
#out.show()
addStackTracks(imp, data, xoffset, yoffset, xscale)
imp.updateAndDraw()




