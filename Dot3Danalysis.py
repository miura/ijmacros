"""
Kota Miura (cmci.embl.de)
20101203-13

dot detection by ch1 and measurment in ch2 with a bit wider area
dot positions are detected in 3D space.
dots too close to the neighbors are omitted frommeasurement
since focal depth is thick, 3D intensity measurement is currently omitted. 
"""
import java.lang.Thread as thr
import java.lang.Math as Math
import ij.Macro as Macro
#import emblcmci.pt3D.Dot_Detector_3D as dot3D
import ij.plugin.RGBStackMerge as RGBStackMerge
import ij.process.ImageConverter as ImageConverter
from ij.gui import OvalRoi
from ij.process import ImageStatistics as IS
from ij.measure import Calibration
from ij.measure import ResultsTable
from ij.plugin import HyperStackReducer
from array import array, zeros
import math

#Channel Assignment
ChHoechst = 1
ChReference = 3
ChTarget = 2

# Diameter of the oval ROIfor measurement
thdist = 9

#parameters for dot detection using mosaic tool
radius = 3
cutoff = 0
percentile = 0.01

def NeighborChecker(xar, yar, zar, switch):
	""" Check the distance to neighbors, and count the number of neighbors below thdist. """
	global thdist
	neighborA = zeros('d', len(xar))
	if switch:
		for i in range(len(xar)):
			cx = xar[i]
			cy = yar[i]
			cz = zar[i]	 
			for j in range(len(xar)):
				if j != i :
					dist = Math.sqrt( Math.pow((cx - xar[j]), 2) + Math.pow((cy - yar[j]), 2))
					if dist < thdist:
						if Math.abs(cz - zar[j]) < 2:
							logstr = ".... Dot%d - Dot%d too close: dist = %d" % (i, j, dist)
							IJ.log(logstr)
							print logstr
							neighborA[i] += 1
			if neighborA[i] > 0:
				IJ.log("---> Dot%d rejected" % (i))
				print "---> Dot", i, " rejected"
	return neighborA

def lsmChannelExtractrer(imp, extch):
	width = imp.getWidth()
	height = imp.getHeight()
	channels = imp.getNChannels()
	slices = imp.getNSlices()
	frames = imp.getNFrames()
	bitDepth = imp.getBitDepth()
	size = slices*frames
	reducer = HyperStackReducer(imp)
	if extch > channels:
		return 0
	else:
		c = extch
		imp.setPosition(c, 1, 1)
		stack2 = ImageStack(width, height, size)
		stack2.setPixels(imp.getProcessor().getPixels(), 1)
		newtitile = "C%d-%s" % (c, imp.getTitle())
		imp2 = ImagePlus(newtitile, stack2)
		#stack2.setPixels(null, 1)
		imp.setPosition(c, 1, 1)
		imp2.setDimensions(1, slices, frames)
		imp2.setCalibration(imp.getCalibration())
		reducer.reduce(imp2);
		if imp2.getNDimensions()>3:
			imp2.setOpenAsHyperStack(true)
		imp.changes = False
		return imp2

def BinarizeChromosome(impbin):
	"""
	Make mask using chromosome. Automatic thresholding by Moment is a bit smaller than Otsu. 
	"""
	IJ.run(impbin, "Gaussian Blur...", "sigma=2 stack")
	impbin.setSlice(int(math.floor(impbin.getStackSize() / 2)))
	#IJ.setAutoThreshold(impbin, "Otsu dark")
	IJ.setAutoThreshold(impbin, "Moments dark")
	IJ.run(impbin, "Convert to Mask", "  black")
	IJ.run(impbin, "Divide...", "value=255 stack")
	IJ.run(impbin, "16-bit", "")
	
orgimp = IJ.getImage()
#Hoechst
impch1 = lsmChannelExtractrer(orgimp, ChHoechst)
#reference
impch2 = lsmChannelExtractrer(orgimp, ChReference)
#target
impch3 = lsmChannelExtractrer(orgimp, ChTarget)

orgimp.close()

BinarizeChromosome(impch1)
impch1.show()

ic = ImageCalculator()
#TODO
imp = ic.run("Multiply create stack", impch1, impch2);
imp.show()


IJ.run(imp, "Background Subtractor", "length=10 stack")
#options = "radius=3 cutoff=1 percentile=0.01"
options = "radius=%d cutoff=%d percentile=%f" % (radius, cutoff, percentile)
thread = thr.currentThread()
original_name = thread.getName()
thread.setName("Run$_my_batch_process")
Macro.setOptions(thr.currentThread(), options)
pt = IJ.runPlugIn(imp, "emblcmci.pt3d.Dot_Detector_3D", "")

impdimA = imp.getDimensions()
ims = imp.createEmptyStack()
for i in range(impdimA[3]): 
	ims.addSlice(None, ByteProcessor(impdimA[0], impdimA[1]))
imp2 = ImagePlus("test", ims)

nSlices = imp2.getNSlices()

rt = ResultsTable.getResultsTable()
xindex = rt.getColumnIndex("x")
yindex = rt.getColumnIndex("y") 
zindex = rt.getColumnIndex("z")
xA = rt.getColumn(xindex)
yA = rt.getColumn(yindex)
zA = rt.getColumn(zindex)

neighbornumA = NeighborChecker(xA, yA, zA, True)

for i in range(len(xA)):
	print xA[i], yA[i], zA[i], " .. Neighbor", neighbornumA[i]   
#	if xA[i] > 0:
	if neighbornumA[i] == 0:	
		cslice=Math.round(zA[i])+1
		if cslice > 0 and cslice <= nSlices:
			ip = imp2.getStack().getProcessor(cslice)
			ip.set(Math.round(yA[i]), Math.round(xA[i]), 255)
#imp2.show()


#MEASUREMENT 
#XYpositions is inverted (like the plot) and shift in z position

xyoffset = math.floor(thdist/2)
options = IS.INTEGRATED_DENSITY | IS.AREA | IS.MEAN | IS.STD_DEV
cal = Calibration()
rt = ResultsTable()
ct = 0
for i in range(len(xA)):
	if neighbornumA[i] == 0:
		ipch2 = impch2.getImageStack().getProcessor(int(zA[i]) + 1)
		ipch3 = impch3.getImageStack().getProcessor(int(zA[i]) + 1)
		dotRoi = OvalRoi(int(yA[i] - xyoffset), int(xA[i] - xyoffset), thdist, thdist)	
		ipch2.setRoi(dotRoi)
  		#stats = IS.getStatistics(ip, options, imp.getCalibration())
  		stats = IS.getStatistics(ipch2, options, cal)
		ipch3.setRoi(dotRoi)
  		statsch3 = IS.getStatistics(ipch3, options, cal)
  		print "dot", i
  		print "...ch2 TotalInt ", stats.area * stats.mean
  		print "...ch2 Area     ", stats.area
  		print "...ch2 mean     ", stats.mean
  		print ".."  		
  		print "...ch3 TotalInt ", statsch3.area * statsch3.mean
  		print "...ch3 Area     ", statsch3.area
  		print "...ch3 mean     ", statsch3.mean
	 	rt.incrementCounter()
	 	rt.setValue("DotID", ct, i)
	 	rt.setValue("DotX", ct, yA[i])
	 	rt.setValue("DotY", ct, xA[i])
	 	rt.setValue("DotZ", ct, zA[i])	 	
		rt.setValue("Ch2_TotalIntensity", ct, stats.area * stats.mean)
		rt.setValue("Ch2_MeanIntensity", ct, stats.mean)
		rt.setValue("Ch3_TotalIntensity", ct, statsch3.area * statsch3.mean)
		rt.setValue("Ch3_meanIntensity", ct, statsch3.mean)
		ct += 1
rt.show("Dot Intensity")


#AREA, AREA_FRACTION, CENTER_OF_MASS, CENTROID, CIRCULARITY, ELLIPSE, FERET, 
#INTEGRATED_DENSITY, INVERT_Y, KURTOSIS, LABELS, LIMIT, MAX_STANDARDS, MEAN, 
#MEDIAN, MIN_MAX, MODE, PERIMETER, RECT, SCIENTIFIC_NOTATION, SHAPE_DESCRIPTORS, 
#SKEWNESS, SLICE, STACK_POSITION, STD_DEV

# preparing merged stack with detected dots. 

merge = RGBStackMerge()
#stacks = Array()
#stacks[0] = imp2.getImageStack()
#stacks[1] = imp.getImageStack()
#imgconv = ImageConverter(imp)
#imgconv.setDoScaling(True)
#imgconv.convertToGray8() 
IJ.run(impch2, "Enhance Contrast", "saturated=0.02 use")
IJ.run(impch2, "8-bit", "")
IJ.run(impch3, "Enhance Contrast", "saturated=0.02 use")
IJ.run(impch3, "8-bit", "")
stacks = array(ImageStack, [imp2.getImageStack(), impch2.getImageStack(), impch3.getImageStack()])
impmerged = merge.createComposite(imp2.getWidth(), imp2.getHeight(), imp2.getStackSize(), stacks, True)
impmerged.show()

impch1.changes = False
impch1.close()
imp.changes = False
imp.close()









