from org.rosuda.REngine.Rserve import RConnection
from ij.gui import Roi, Overlay
import os, csv

def getPeaks(roi, c):
	profile = roi.getPixels()
	c.assign("prof", profile)
#	pks = c.eval("SpectrumSearch(prof, sigma=3, threshold=25, background=TRUE, iterations=20, markov=TRUE, window=5)").asList()
	pks = c.eval("SpectrumSearch(prof, sigma=2, threshold=10, background=TRUE, iterations=20, markov=TRUE, window=2)").asList()
	pksY = pks[0].asIntegers()
	#for i in pksX:
	#	print roi.x1, i
	#	rois.append(PointRoi(roi.x1, roi.y1 + i))
	#ol = Overlay() 
	#for aroi in rois:
	#	ol.add(aroi)
	#imp.setOverlay(ol)
	return pksY
	
	
c = RConnection()
x = c.eval("R.version.string")
print x.asString()
print c.eval("library(Peaks)").asString()

imp = IJ.getImage()
roi = imp.getRoi()
alldata = []
maxlen = 0
totallen = 0
if roi.getType() == Roi.LINE:
	#print "a line roi"
	for i in range(imp.getStackSize()):
		imp.setSlice(i+1)
		peakYs = getPeaks(roi, c)
		peakTs = [i+1 for j in range(len(peakYs))]
		alldata.append(peakTs)
		alldata.append(peakYs)
		if len(peakTs) > maxlen:
			maxlen = len(peakTs)
		totallen = totallen + len(peakTs)

# prepare path
root = "/Users/miura/Dropbox/codes/girogia/data"
filename = "wild5.csv"
fullpath = os.path.join(root, filename)
print fullpath
 
# open the file first (if its not there, newly created)
f = open(fullpath, 'wb')
 
# create csv writer
writer = csv.writer(f)
 
# for loop to write each row
'''
for i in range(maxlen):
	arow = []
	for acol in alldata:
		if len(acol) > i:
			arow.append(acol[i])
		else:
			arow.append(" ")
			
	writer.writerow(arow)
'''
for i in range(len(alldata)/2):
	td = alldata[i * 2]
	yd = alldata[i * 2 + 1]
	for j in range(len(td)):
		writer.writerow([td[j], yd[j]]) 
#writer.writerows([data1, data2, data3])
 
# close the file. 
f.close()

	
c.close()
