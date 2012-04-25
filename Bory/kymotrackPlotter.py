# plot bory tracking results onto 3Dkymograph. 
# ** filepath and dimension of the kymograph should be adjusted manually
# Kota Miura (miura@embl.de)
# 20120419
from ij import IJ
from util.opencsv import CSVReader
from java.io import FileReader
from java.awt import Color as JColor 
def readCSV(filepath):
   reader = CSVReader(FileReader(filepath), "\t")
   ls = reader.readAll()
   f, x, y, z =[], [], [], []
   for i in range(len(ls)):
      if i is not 0:
         f.append(ls.get(i)[1])
         x.append(ls.get(i)[4])
         y.append(ls.get(i)[5])
         z.append(ls.get(i)[6])
         #print x[i-1], y[i-1], z[i-1]
   return f, x, y, z                     
 
filepath = 'Z:/bory/20120415_tracking/Statistics_Ch0.xls'
#filepath = 'Z:/bory/20120415_tracking/Statistics_Ch1.xls'
f, x, y, z = readCSV(filepath)
print len(x), f[0], x[0], y[0], z[0]
imp = IJ.getImage()
ImageConverter(imp).convertToRGB() 
ip = imp.getProcessor()
ip.setColor(JColor(255,0,0)) # color assignment
for i in range(len(f)):
	#xt
	ip.drawPixel(int(round(x[i])), int(f[i]))
	#yt
	#ip.drawPixel(int(round(y[i])), int(f[i]))
	#zt	
	#ip.drawPixel(int(round(z[i]))-1, int(f[i]))
imp.updateAndDraw()
	