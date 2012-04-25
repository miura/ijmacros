# Loads data file of Bories project. 

from ij import IJ
from util.opencsv import CSVReader
from java.io import FileReader
 
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
f, x, y, z = readCSV(filepath)
print len(x), f[0], x[0], y[0], z[0]
