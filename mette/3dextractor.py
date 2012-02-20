"""
Converts 4D hyperstack to 3D stack with ortho-views in xy, xz, yz, each with Max projections.
Then 2D vectors are plotted in each slice, according to the specified data file. 
(output of 4D visualizaiton plotter, Plot_4D.jar and net displacements)

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
imp = IJ.getImage()
stkA = ArrayList()
for i in range(1, 4):
#for i in range(1, imp.getNFrames()):
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
filepath = '/Users/miura/Dropbox/Mette/20_23h/20_23hrfull_corrected_1_6_6_netdispZ40.csv'
filename = os.path.basename(filepath)
newfilename = os.path.join(os.path.splitext(filename)[0], '_plotStack.tif')
out.setTitle(os.path.basename(filename)+'_OutStack.tif')

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
for d in data:
   frame = int(d[1])
   if frame < out.getStack().getSize():
      x1 = int(round(float(d[2]) / xscale))
      y1 = int(round(float(d[3]) / yscale))
      z1 = int(round(float(d[4]) / zscale))
      x2 = int(round(float(d[5]) / xscale))
      y2 = int(round(float(d[6]) / yscale))
      z2 = int(round(float(d[7]) / zscale))
      direction = float(d[8])
      if PLOT_ONLY_IN_FRAME1:
         ip = out.getStack().getProcessor(1)
      else:
         ip = out.getStack().getProcessor(frame+1)      
      if direction <= 0:
         ip.setColor(Color(255, 100, 100))
      else:
         ip.setColor(Color(100, 100, 255))
      ip.setLineWidth(2)
      ip.drawLine(x1, y1, x2, y2)
      ip.drawLine(x1, yoffset+ z1, x2, yoffset+z2)
      ip.drawLine(xoffset+z1, y1, xoffset+z2, y2)
out.updateAndDraw()
# plot 
out.show()
