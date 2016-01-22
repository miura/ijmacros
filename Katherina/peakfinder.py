from org.rosuda.REngine.Rserve import RConnection
from ij.gui import Roi, Overlay

c = RConnection()
x = c.eval("R.version.string")
print x.asString()
print "Loaded Package:", c.eval("library(Peaks)").asString()

imp = IJ.getImage()
roi = imp.getRoi()
if roi.getType() == Roi.LINE:
	print "a line roi found"
	profile = roi.getPixels()
	c.assign("prof", profile)
#	pks = c.eval("SpectrumSearch(prof, sigma=1, threshold=25, background=TRUE, iterations=20, markov=TRUE, window=5)").asList()
#	pks = c.eval("SpectrumSearch(prof, sigma=3, threshold=25, background=TRUE, iterations=20, markov=TRUE, window=5)").asList()
#	pks = c.eval("SpectrumSearch(prof, sigma=3, threshold=2, background=TRUE, iterations=20, markov=TRUE, window=2)").asList()
	pks = c.eval("SpectrumSearch(prof, sigma=2, threshold=2, background=TRUE, iterations=20, markov=FALSE, window=2)").asList()

	pksX = pks[0].asIntegers()
	rois = []
	print "Number of Peaks:", len(pksX)
	for i in pksX:
		#print "\t", roi.x1, i
		rois.append(PointRoi(roi.x1, roi.y1 + i))
	ol = Overlay() 
	for aroi in rois:
		ol.add(aroi)
	imp.setOverlay(ol)
	
c.close()
