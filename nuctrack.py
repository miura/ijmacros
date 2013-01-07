''' Intensity dynamics in the nuclear periphery
with Andrea Boni, Ellenberg lab
Kota Miura (miura@embl.de)

Requires: 2 channel time series image stack. ch1 = signail, ch2 = dapi
'''

  # store all results in the table.
  # list nucleus in the first frame
  # create instance of nucpath for each
# 	there should be path plotted, to check linking. 
  # store path for each, series of next frame numbers. 
  # for each nucelus, 
  #	esttimate the boudary rectangle that fits the nucelus
  #	extract substack (of binary)
  #	create rim
  #	do measurement	
# show intensity dynamics for each, all. 
# reject edge touching nucleus

from java.lang import Double
from ij.gui import Roi
from ij import IJ, ImageStack, ImagePlus
from ij.plugin.filter import ParticleAnalyzer as PA
from ij.plugin import ChannelSplitter as CS
from ij.plugin import Duplicator
from ij.measure import ResultsTable
from ij.measure import Measurements as Meas
from java.util import ArrayList
import jarray
from java.lang import Math
G_RimHalfWidth = 3

def segmentNuc(impc2):
	impdup = Duplicator().run(impc2)
	IJ.run(impdup, "8-bit", "")
	IJ.run(impdup, "Gaussian Blur...", "sigma=1.5 stack")
#	AutoThresholder().getThreshold(AutoThresholder.Method.valuOf('Otsu'), int[] histogram) 
	IJ.setAutoThreshold(impdup, "Otsu dark")
	IJ.run(impdup, "Convert to Mask", "stack")
 	#IJ.setAutoThreshold(impdup, "Otsu dark")
	#opt = PA.SHOW_MASKS + PA.SHOW_RESULTS + PA.EXCLUDE_EDGE_PARTICLES + PA.INCLUDE_HOLES # option for stack missing
	opt = PA.SHOW_MASKS + PA.EXCLUDE_EDGE_PARTICLES + PA.INCLUDE_HOLES # option for stack missing
	##area mean centroid bounding integrated stack redirect=None decimal=4
	meas = Meas.AREA + Meas.MEAN + Meas.CENTROID + Meas.RECT + Meas.INTEGRATED_DENSITY + Meas.STACK_POSITION
	rt = ResultsTable().getResultsTable()
	pa = PA(opt, meas, rt, 10.0, 300000.0, 0, 1.0)
	PA.processStack = True
	pa.setHideOutputImage(True)
	##run("Analyze Particles...", "size=800-Infinity circularity=0.00-1.00 pixel show=Masks display exclude include stack");
	outstack = ImageStack(impdup.getWidth(), impdup.getHeight())
	for i in range(1,impdup.getStackSize()+1):
		impdup.setSlice(i)
		pa.analyze(impdup)
		impbin = pa.getOutputImage()
		outstack.addSlice(impbin.getProcessor())
 	impbin = ImagePlus("out", outstack)
	IJ.run(impbin, "Invert LUT", "")
	#IJ.run(impbin, "Fill Holes", "stack")
	return impbin, rt

def extractRIM(impbin, iteration):
	IJ.run(imp, "Options...", "iterations=1 count=1 edm=Overwrite do=Nothing");
	impErode = Duplicator().run(impbin)
	impDilate = Duplicator().run(impbin)	
#	resized = CanvasResizer().expandStack(impDilate.getStack(), impDilate.getWidth()+2*iteration, impDilate.getHeight()+2*iteration, iteration, iteration)
#	impDilate.setStack(None, resized);
	for j in range(impErode.getStackSize()):
		ipe = impErode.getStack().getProcessor(j+1)
		ipe.setBackgroundValue(0)
		ipd = impDilate.getStack().getProcessor(j+1)
		ipd.setBackgroundValue(0)
		for i in range(iteration):
			ipe.erode()
			ipd.dilate()
#		IJ.run(impErode, "Dilate", "stack")
#		IJ.run(impDilate, "Erode", "stack")
#	resized = CanvasResizer().expandStack(impDilate.getStack(), impDilate.getWidth()-2*iteration, impDilate.getHeight()-2*iteration, -1*iteration, -1*iteration)
#	impDilate.setStack(None, resized);
#	impErode.show()
#	Duplicator().run(impDilate).show()	
	for i in range(1, impbin.getStackSize()+1):
		impDilate.setSlice(i)
		impErode.setSlice(i)
		ImageCalculator().calculate("XOR", impDilate, impErode)
	return impDilate;

# transfer colums in ResultsTable to arrays
def parseResultsTable(rt):
	indexA = []
	cxA = rt.getColumnAsDoubles(rt.getColumnIndex("X"))
	cyA = rt.getColumnAsDoubles(rt.getColumnIndex("Y"))
	bxA = rt.getColumnAsDoubles(rt.getColumnIndex("BX"))
	byA = rt.getColumnAsDoubles(rt.getColumnIndex("BY"))
	widthA = rt.getColumnAsDoubles(rt.getColumnIndex("Width"))
	heightA = rt.getColumnAsDoubles(rt.getColumnIndex("Height"))
	sliceA = rt.getColumnAsDoubles(rt.getColumnIndex("Slice"))
#	cyA = rt.getColumnAsDoubles(rt.getColumnIndex("NextFrame"))
	for i in range(len(cxA)):
		indexA.append(i+1)
	return cxA, cyA, bxA, byA, widthA, heightA, sliceA, indexA
	
# collect centroids information in the initial frame
# then follow 'nextID' to load successive nucleus
# all paths are then stored in a dictionary, key=pathid and value = Path instance
def parseNucs(indexA, cxA, cyA, bxA, byA, widthA, heightA, frameA, nextidA):	
	pathlist = {}
	for i in range(0, len(frameA)):
		n = Nuc(indexA[i])
		n.setParam(cxA[i], cyA[i], bxA[i], byA[i], widthA[i], heightA[i], frameA[i], nextidA[i])
		if int(frameA[i]) == 1:
			p = Path(indexA[i])
			p.addNuc(n)
			pathlist[indexA[i]] = p
			#print 'pathid', indexA[i]
			while n.nextid != -1 and n.nextid != p.nucs.get(len(p.nucs)-1).nucid:
				nid = n.nextid
				#print '...', nid
				n = Nuc(nid)
				n.setParam(cxA[nid], cyA[nid], bxA[nid], byA[nid], widthA[nid], heightA[nid], frameA[nid], nextidA[nid])
				p.addNuc(n)
	return pathlist

# single path (time series of nucelus)
class Path:
	def __init__(self, pathid):
		self.pathid = pathid
		self.nucs = ArrayList()
		self.touchesEdge = False
		self.minbx = 0
		self.minby = 0
		self.maxbx = 0
		self.maxby = 0
		self.binstack = ImagePlus()
		self.rimstack = ImagePlus()
		self.actualbx = 0
		self.actualby = 0
		self.actualww = 0
		self.actualhh = 0				 		 
	def addNuc(self, nuc):
		self.nucs.add(nuc)
	def getNucs(self):
		return self.nucs
	def getPathID(self):
		return self.pathid
	def settouchesEdge(self, touches):
		self.touchesEdge = touches

	def clearOtherNucs(self, ip, wandx, wandy):
		wandx, wandy = int(wandx), int(wandy)
		if ip.getPixel(wandx, wandy) == 255:
			wan = Wand(ip)
			wan.autoOutline(wandx, wandy)
			#print "selected", wan.npoints
			roi = ShapeRoi(PolygonRoi(wan.xpoints , wan.ypoints, wan.npoints, Roi.FREEROI))
			allroi = ShapeRoi(Roi(0,0, ip.getWidth(), ip.getHeight()))
			#imp.setRoi(roi.xor(allroi))
			ip.setColor(0)
			ip.fill(roi.xor(allroi))
	#		imp.updateAndDraw()

	def extractSubStacks(self, imp, start, end, offset):
		self.actualbx = self.minbx - offset
		self.actualby = self.minby - offset
		if self.actualbx < 0:
			self.actualbx = 0
		if self.actualby < 0:
			self.actualby = 0
		self.actualww = self.maxbx-self.minbx + 2*offset
		if self.minbx + self.actualww > imp.getWidth()-1:
			self.actualww = imp.getWidth() - self.minbx -1
		self.actualhh = self.maxby-self.minby + 2*offset
		if self.minby + self.actualhh > imp.getHeight()-1:
			self.actualhh = imp.getHeight() - self.minby -1
			
		#imp.setRoi(self.minbx, self.minby, self.maxbx-self.minbx, self.maxby-self.minby)
		imp.setRoi(self.actualbx, self.actualby, self.actualww, self.actualhh)
		subimp = Duplicator().run(imp, int(start), int(end))
		return subimp

	def defaultextractSubStacks(self, imp):
		start = self.nucs.get(0).frame
		end = self.nucs.get(len(self.nucs)-1).frame		
		imp.setRoi(self.actualbx, self.actualby, self.actualww, self.actualhh)
		subimp = Duplicator().run(imp, int(start), int(end))
		return subimp
			
	# returns a substack, for both ch1 and ch2
	def getPathStack(self, imp, offset):
		start = self.nucs.get(0).frame
		end = self.nucs.get(len(self.nucs)-1).frame		
		subimp = self.extractSubStacks(imp, start, end, offset)
		return subimp

	# returns a rim stack of ch2
	def getRimSubStack(self, binimp, morphiter):
		subimp =  self.getPathStack(binimp, morphiter + 15) # 15 is to have some more space at the edge
		for i in range(subimp.getStackSize()):
			wx = self.nucs.get(i).x - self.actualbx
			wy = self.nucs.get(i).y - self.actualby			
			self.clearOtherNucs(subimp.getStack().getProcessor(i+1), wx , wy) 
		
		rimimp = extractRIM(subimp, morphiter)
		return rimimp
		
# Single nucleus class
class Nuc:
	def __init__(self, nucid):
		self.nucid = nucid
		self.area = 0
		self.mean = 0
		self.max = 0
		self.min = 0
		self.sd = 0
		self.roi = Roi(0, 0, 1, 1)
				
	def setParam(self, x, y, bx, by, width, height, frame, nextid):
		self.x = x
		self.y = y
		self.bx = bx
		self.by = by
		self.width = width
		self.height = height
		self.frame = frame
		self.nextid = nextid
	def getNucID(self):
		return self.nucid
	def getNextID(self):
		return self.nextid
	def getParam(self):
		return self.x, self.y, self.bx, self.by, self.width, self.height, self.frame, self.nextid
	def setMeasurementResults(self, mean, max, min, sd, area):
		self.mean, self.max, self.min, self.sd, self.area = mean, max, min, sd, area
	def getMeasurementResults(self):
		return self.mean, self.max, self.min, self.sd, self.area
	def setRoi(self, roi):
		self.roi = roi	
		
	
# check if nucleus is present through the sequence
# 1. for a centroid, if that position in the next frame is none-positive, then there is no nucleus. 
def checkPresenceinNextFrame(impbin, rt, cxA, cyA, sliceA):
	stacksize = impbin.getStackSize()
	hasNextFrame = ArrayList()
	for i in range(len(cxA)):
		if sliceA[i] < stacksize:
			#impbin.setSlice(sliceA[i])
			pixval = impbin.getStack().getProcessor(int(sliceA[i])+1).getPixel(int(cxA[i]), int(cyA[i]))
			#print int(cxA[i]), int(cyA[i]), pixval
			hasNextFrame.add(pixval == 255)
	return hasNextFrame

def linkNucelus(cxA, cyA, sliceA, hasNextFrame):
	nextFrame = list(range(len(cxA)))
	for i in range(len(hasNextFrame)):
		if (hasNextFrame.get(i)):
			currentSlice = int(sliceA[i])
			mindist = 10000
			for j in range(len(sliceA)):
				if int(sliceA[j]) == currentSlice+1 :
					#print currentSlice, int(sliceA[j])
					currentdist = distance(cxA[i], cyA[i], cxA[j], cyA[j])
					if mindist > int(currentdist):
						#print currentdist
						mindist = currentdist
						nextFrame[i] = j
			#print i, 'slice', sliceA[i], 'to ', nextFrame[i], ': Minimum', mindist
		else:
			nextFrame[i] = -1
	return nextFrame
					
					
					
def distance(a, b, c, d):
	ans = pow((pow(a-c, 2) + pow(b-d, 2)), 0.5)
	return ans

def write2ResultsTable(rt, heading, dataA):
	for i in range(len(dataA)):
		rt.setValue(heading, i, Double.valueOf(dataA[i]))

def setROIsize(pathdict):
	for pathid, path in pathdict.iteritems():
		abxA, abyA, abwA, abhA = parseBounds(path.nucs)
		path.minbx = int(reduce(Math.min, abxA))
		path.minby = int(reduce(Math.min, abyA))
		path.maxbx = int(reduce(Math.max, abwA))
		path.maxby = int(reduce(Math.max, abhA))
		#print pathid, 'Bound', path.minbx, path.minby, path.maxbx, path.maxby
				 
def parseBounds(nucs):
	abxA = []
	abyA = [] 
	abwA = []
	abhA = []
	for nuc in nucs:
		abxA.append(nuc.bx)
		abyA.append(nuc.by)
		abwA.append(nuc.bx + nuc.width)
		abhA.append(nuc.by + nuc.height)
	return abxA, abyA, abwA, abhA
	

def clearOtherNucs(ip, wandx, wandy):
	if ip.getPixel(wandx, wandy) == 255:
		wan = Wand(ip)
		wan.autoOutline(wandx, wandy)
		#print "selected", wan.npoints
		roi = ShapeRoi(PolygonRoi(wan.xpoints , wan.ypoints, wan.npoints, Roi.FREEROI))
		allroi = ShapeRoi(Roi(0,0, ip.getWidth(), ip.getHeight()))
		#imp.setRoi(roi.xor(allroi))
		ip.setColor(0)
		ip.fill(roi.xor(allroi))
#		imp.updateAndDraw()

# simlar to Edit > Selection > selection from mask
def roiFromMask255(ip):
	ip.setThreshold(255, 255, ImageProcessor.NO_LUT_UPDATE);
	#IJ.runPlugIn("ij.plugin.filter.ThresholdToSelection", "");
	aroi = ThresholdToSelection().convert(ip)
	return aroi

# measure intensity dynamics and store in path instances
def measureIntDynamics(pathdict, impbin, GdilateIter, impc1):
	for pathid, path in pathdict.iteritems():
		subrim = path.getRimSubStack(impbin, GdilateIter)
		subch1 =  path.defaultextractSubStacks(impc1)
		for i in range(subrim.getStackSize()):
			#subrim.setSlice(i+1)
			roi = roiFromMask255(subrim.getStack().getProcessor(i+1))
			#print 'nuc',i, ' - roi', roi.toString()
			subch1.setSlice(i+1)
			subch1.setRoi(roi)
			stat = subch1.getStatistics(Meas.MEAN + Meas.MIN_MAX + Meas.AREA + Meas.STD_DEV)
			path.nucs.get(i).setMeasurementResults(stat.mean, stat.max, stat.min, stat.stdDev, stat.area)  
			path.nucs.get(i).setRoi(roi)
		'''
		IJ.run(subrim, "Red", "")	
		images = jarray.array([subrim, subch1], ImagePlus)
		comb = RGBStackMerge().mergeHyperstacks(images, False)  
		comb.setRoi(path.nucs.get(0).roi, True)
		comb.show()
		'''

def creatResultsCompisite(pathdict, impbin, impsig):
	impbin.killRoi()
	impsig.killRoi()
	impid = Duplicator().run(impbin)
	IJ.run(impbin, "Red", "")
	for i in range(impid.getStackSize()):
		impid.getStack().getProcessor(i+1).setColor(0)
		impid.getStack().getProcessor(i+1).fill()
		impid.getStack().getProcessor(i+1).setColor(255)
	for pathid, path in pathdict.iteritems():
		for nuc in path.nucs:
			ip = impid.getStack().getProcessor(int(nuc.frame))
			ip.setColor(255)
			ip.drawString(str(pathid), int(nuc.x), int(nuc.y))
			#print 'Draw Path ID:',str(pathid)			 	
	images = jarray.array([impbin, impsig, impid], ImagePlus)
	comb = RGBStackMerge().mergeHyperstacks(images, False)
	comb.setTitle('Measurement Map.tif')
	return comb
	#return impid

def getMaxforAllIntensity(pathdict):
	mean = []
	max = []
	pathlength = []
	for pathid, path in pathdict.iteritems():
		pathlength.append(len(path.nucs))
		for nuc in path.nucs:
			mean.append(float(nuc.mean))
			max.append(float(nuc.max))
	meanMax = reduce(Math.max, mean)
	maxMax = reduce(Math.max, max)
	meanMin = reduce(Math.min, mean)
	maxMin = reduce(Math.min, max)
	pathlenMax = reduce(Math.max, pathlength)
	return meanMax, maxMax, meanMin, maxMin, pathlenMax
			

from java.awt import Color
def intensityPlotter(path, pathid, meanMax, maxMax, meanMin, maxMin, pathlenMax):
	#path = pathdict[pathid]
	if len(path.nucs) < 5:
		print 'Path', pathid, ' omitted since only', str(len(path.nucs)), 'p[oints sampled'
		return
	mean = []
	sd = []
	max = []
	frames = []
	for nuc in path.nucs:
		mean.append(float(nuc.mean))
		sd.append(float(nuc.sd))
		max.append(float(nuc.max))
		frames.append(float(nuc.frame))		
	jmean = jarray.array(mean , 'd')
	jframes =jarray.array(frames , 'd')
	jmax = jarray.array(max , 'd')
	plottitle = "Plot nucleus " + str(int(pathid))
#	pt = Plot(plottitle, "Frames", "Intensity")
	pt = Plot(plottitle, "Frames", "Intensity")
	pt.setLimits(0, pathlenMax+1, meanMin, maxMax)
	pt.setColor(Color.red) 
	pt.addPoints(jframes, jmean, pt.LINE)
	pt.setColor(Color.lightGray ) 
	pt.addPoints(jframes, jmax, pt.LINE)
	#pt.addPoints(jframes, jmean, pt.CIRCLE)
	#pt.draw()
	pt.show() 

# added on 20121129
# argument is the results table of above
# returned value can be listed in the ROi Manager by
#rmgr = RoiManager.getInstance()
#if rmgr is None:
	#rmgr = RoiManager()
#for aroi in roisA:
	##imp.setRoi(aroi)
	#rmgr.addRoi(aroi)

def getTrackRois(resultstable):
	rt = resultstable
	nextframeA = rt.getColumn(rt.getColumnIndex('NextFrame'))
	sliceA = rt.getColumn(rt.getColumnIndex('Slice'))
	xA = rt.getColumn(rt.getColumnIndex('X'))
	yA = rt.getColumn(rt.getColumnIndex('Y'))
	imp = IJ.getImage()
	donecheckA = list(range(len(nextframeA)))
	roisA = []
	for i, slicenum in enumerate(sliceA):
		if slicenum == 1:
			roix = [int(xA[i])]
			roiy = [int(yA[i])]
			ci = i
			print 'Start', roix, roiy
			count = 0
			while (nextframeA[int(ci)] != -1) and (slicenum < 160) and count<160:
				nexti = int(nextframeA[ci])
				nextslice = int(sliceA[nexti])
				roix.append(int(xA[nexti]))
				roiy.append(int(yA[nexti]))
				#print '...', int(xA[nexti]), int(yA[nexti])
				ci = nexti
				slicenum = nextslice
				count +=1
			#print roix
			if len(roix) > 1:
				jroix = jarray.array(roix, 'f')
				jroiy = jarray.array(roiy, 'f')
				pr = PolygonRoi(jroix, jroiy , len(roix), Roi.POLYLINE)
				roisA.append(pr)

GdilateIter = 2

imp = IJ.getImage()
#chsA = CS.split(imp)
#impc1 = chsA[0]
#impc2 = chsA[1]
impc2 = imp

IJ.run("Clear Results", "");
#IJ.run(impc1, "Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
IJ.run(impc2, "Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
impbin, rt = segmentNuc(impc2, GdilateIter)
#imprim = extractRIM(impbin, GdilateIter)
rt.show("Results")
cxA, cyA, bxA, byA, widthA, heightA, frameA, indexA = parseResultsTable(rt)
hasNextFrame = checkPresenceinNextFrame(impbin, rt, cxA, cyA, frameA)
nextFrame = linkNucelus(cxA, cyA, frameA, hasNextFrame)
'''
for i in nextFrame:
	print i, 'slice', frameA[i], 'to ', nextFrame[i]
'''
write2ResultsTable(rt, 'NextFrame', nextFrame)
rt.show("Results")
pathdict = parseNucs(indexA, cxA, cyA, bxA, byA, widthA, heightA, frameA, nextFrame)
setROIsize(pathdict)

#'''
for pathid, path in pathdict.iteritems():
	print pathid, 'path length=', len(path.nucs) ,'x:', path.nucs.get(0).x, 'y:', path.nucs.get(0).x
	print pathid, '... bounds', path.minbx, path.minby, path.maxbx, path.maxby
#'''

#measureIntDynamics(pathdict, impbin, GdilateIter, impc1)
'''
for nuc in pathdict[2].nucs:
	print nuc.getMeasurementResults()
	print nuc.roi.toString()
	
subrim = pathdict[3].getRimSubStack(impbin, GdilateIter)
subrim.setRoi(pathdict[3].nucs.get(0).roi)
subrim.show()
'''
#comb = creatResultsCompisite(pathdict, imprim, impc1)
#comb.show()

#meanMax, maxMax, meanMin, maxMin, pathlenMax = getMaxforAllIntensity(pathdict)
#print 'Max of mean', meanMax, 'Max of max', maxMax
#print 'Min of mean', meanMin, 'Min of max', maxMin
'''
for pathid, path in pathdict.iteritems():
	intensityPlotter(path, pathid, meanMax, maxMax, meanMin, maxMin, pathlenMax)
'''
'''
for pathid, path in pathdict.iteritems():
	print '=== path', pathid, '==='
	for nuc in path.nucs:
		print 'frame',nuc.frame, '... mean =', nuc.mean
'''
#keymax = reduce(Math.max, pathdict.keys())		
#for i in range(keymax):
	#if pathdict.has_key(i):
		#intensityPlotter(pathdict[i], i, meanMax, maxMax, meanMin, maxMin, pathlenMax)
		#print '=== path', i, '==='
		#for nuc in pathdict[i].nucs:
			#print 'frame',nuc.frame, '... mean =', nuc.mean
	
