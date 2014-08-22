# 20140617 Kota Miura (miura@embl.de)
# centrosome-centrosome distance
# TODO: cell segmentation better be done based on Nucleus. 

from ij import IJ, Prefs
from fiji.threshold import Auto_Threshold
from ij.plugin.filter import Binary
from ij.plugin.filter import EDM
from ij.plugin.filter import MaximumFinder
from util import FindConnectedRegions as FCR
from ij.plugin import ChannelSplitter
from imagescience.image import Image as FJimage
from imagescience.feature import Laplacian
from ij.plugin import ImageCalculator
from ij.plugin.filter import ParticleAnalyzer as PA
from ij.gui import Line
import math, sys
from ij.plugin.filter import ThresholdToSelection

# Test mode switch
TESTMODE = False #True

# Dot detetion sensitivity: lower = more sensitive
MAXFIND_TOLERANCE = 150

# Particle Size Max & Min
MAXSIZE = 10
MINSIZE = 1

Prefs.blackBackground = True

def splitChannels(orgimp):
	imps = ChannelSplitter.split(orgimp)
	return imps[1], imps[2]

def getNucLabels(segimp):
  fcrresults = FCR().run(segimp, True, True, True, True, True, False, False, 100, 600, 100, True)
  allregionimp =  fcrresults.allRegions
  perRegionlist = fcrresults.perRegion
  infolist =  fcrresults.regionInfo
  return allregionimp, infolist, perRegionlist

def segCentrosome(imp):
  IJ.run(imp, "Unsharp Mask...", "radius=20 mask=0.60");
  #IJ.run(imp, "FeatureJ Laplacian", "compute smoothing=1.0");
  fjimg = FJimage.wrap(imp)
  fjimglap = Laplacian().run(fjimg, 1.0)
  imp2 = fjimglap.imageplus()
  IJ.run(imp2, "Invert", "")
  IJ.run(imp2, "Unsharp Mask...", "radius=1 mask=0.60")
  if TESTMODE == True:
    imp2.show() 
  segip = MaximumFinder().findMaxima( imp2.getProcessor(), MAXFIND_TOLERANCE, ImageProcessor.NO_THRESHOLD, MaximumFinder.SINGLE_POINTS , False, False)
  #IJ.run(imp2, "Find Maxima...", "noise=1800 output=[Single Points]")
  return segip

def maskCreator(fcrimp, labelnum):
  impdup = fcrimp.duplicate()
  impdup.setThreshold(labelnum, labelnum, ImageProcessor.NO_LUT_UPDATE)
  #impdup.

def maxZprojection(stackimp):
  zp = ZProjector(stackimp)
  zp.setMethod(ZProjector.MAX_METHOD)
  zp.doProjection()
  zpimp = zp.getProjection()
  return zpimp  

def particleAnalysis(slicenum, sliceimp, resrt):
  options = PA.SHOW_NONE
  rt = ResultsTable()
  p = PA(options, PA.AREA + PA.CENTROID, rt, MINSIZE, MAXSIZE)
  p.analyze(sliceimp)
  centrosomecounts = rt.getCounter()
  print "-- Region", str(slicenum), "--"
  curCount = resrt.getCounter()
  resrt.setValue("cellID", curCount, slicenum)
  resrt.setValue("counts", curCount, centrosomecounts)
  if centrosomecounts == 0:
    print " .. no centrosome"  
  elif centrosomecounts == 1:
    print " .. Only one centrosome"
#    if rt.getValue("Area", 0) == 1.0:
#    	print " .. Only one centrosome"
#    else:
#    	print " .. one centrosome but Area 1 < : maybe combined"
  elif centrosomecounts == 2:
    print " .. two centrosomes"
    resrt.setValue("c1x", curCount, rt.getValue("X", 0))
    resrt.setValue("c1y", curCount, rt.getValue("Y", 0))
    resrt.setValue("c2x", curCount, rt.getValue("X", 1))
    resrt.setValue("c2y", curCount, rt.getValue("Y", 1))
  else:
    print " .. ", str(centrosomecounts),"centrosomes detected"

def distance(x1, y1, x2, y2):
  xsq = math.pow(x1 - x2, 2)
  ysq = math.pow(y1 - y2, 2)
  return math.pow(xsq + ysq, 0.5)
  
imporg = IJ.getImage()
imgtitle = imporg.getTitle()
imporgDapi, imporgCent = splitChannels(imporg)
impDapi = maxZprojection(imporgDapi)
impCent = maxZprojection(imporgCent)

if TESTMODE == True:
  impCent.show()

ipcentSeg = segCentrosome(impCent)
if TESTMODE == True:
  sys.exit()
impcentSeg = ImagePlus("CentSeg", ipcentSeg)
if TESTMODE == True:
  impcentSeg.show()

imp = impDapi.duplicate()
ImageConverter(imp).convertToGray8() 
hist = imp.getProcessor().getHistogram()
lowTH = Auto_Threshold.Otsu(hist)
print lowTH
 
# if you want to convert to mask, then
imp.getProcessor().threshold(lowTH)

ip = imp.getProcessor()
binner = Binary()
binner.setup("close", None)
binner.run(ip)
binner.setup("fill", None)
binner.run(ip)

EDM().toEDM(ip)
segip = MaximumFinder().findMaxima( ip, 10, ImageProcessor.NO_THRESHOLD, MaximumFinder.SEGMENTED , False, False)

#imp.show()
segimp = ImagePlus("regions", segip)
segimp.show()

segimps, info, perRegionlist = getNucLabels(segimp)
segimps.show()
numregions = len(perRegionlist)
print numregions
ic = ImageCalculator()
stack = ImageStack(impcentSeg.getWidth(), impcentSeg.getHeight())
for amask in perRegionlist:
	masked = ic.run("AND create", amask, impcentSeg)
	stack.addSlice(masked.getProcessor())
regionedimp = ImagePlus("regioned", stack)
#regionedimp.show()

resrt = ResultsTable()
for i in range(regionedimp.getStackSize()):
  aregion = regionedimp.getStack().getProcessor(i+1)
  particleAnalysis(i, ImagePlus("extract", aregion), resrt)

#resrt.show("data")

rm = RoiManager()
for i in range(resrt.getCounter()):
  cc = resrt.getValue("counts", i)
  if cc == 2:
    print "row", i
    x1 = resrt.getValue("c1x", i)
    y1 = resrt.getValue("c1y", i)
    x2 = resrt.getValue("c2x", i)
    y2 = resrt.getValue("c2y", i)
    resrt.setValue("Distance", i, distance(x1, y1, x2, y2))
    print "points", x1, y1, x2, y2
    aroi = Line(x1, y1, x2, y2) 
    rm.addRoi(aroi)
rm.runCommand("Show All")
rm.runCommand("Labels")
resrt.show("results" + imgtitle)

segimp.getProcessor().setThreshold(0, 0, ImageProcessor.NO_LUT_UPDATE)
boundroi = ThresholdToSelection.run(segimp)
rm.addRoi(boundroi)


#perRegionlist[11].show()
