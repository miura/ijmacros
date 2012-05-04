# 4D stack kymograph (by maximum projection)
# 
# requires a 3D timeseries 4D hyperstack opened
# outputs three 2D kymographs (xz, yz, xy projections to y, x, z axes, respectively)
# ...written in conjunction with Bory's project on chromosome locus distance dynamis
# note: z is not scaled by XY scale, so the width of xy projection image
# should be adjusted by resizing according to z factor.   
#
# Kota Miura (miura@embl.de)
# 20120419
# 20120504 fixed a bug to do with signed/unsigned bytes. 

from jarray import zeros
from emblcmci import Extractfrom4D
from ij.process import Blitter
import struct

def ret1Dpos(ww, x, y):
	return y * ww + x
	
def GenByteColormode():
	channel = zeros(256, 'b')
	for i in range(256):
		#channel[i] = (i -128)
		if i<=127:
			channel[i] = i
		else :
			channel[i] = (i - 256)
	cm = LUT(channel, channel, channel)
	return cm
	
def s2u8bit(v):
	return struct.unpack("B", struct.pack("b", v))[0]
def u2s8bit(v):
	return struct.unpack("b", struct.pack("B", v))[0]	
		
# yz max projection to x-axis. 
#stka array of 1D arrays (1D stack)
def maxprojkymoX(stka, ww, hh, dd):
	proj = [] 
	for i in range(ww):
		maxval = 0
		for j in range(dd):
			for k in range(hh):
				curval = stka[j][ret1Dpos(ww, i, k)]
				curval = s2u8bit(curval)
				if maxval < curval:
					maxval = curval
		proj.append(maxval)
	return proj

# xz max projection to y-axis. 
#stka array of 1D arrays (1D stack)
def maxprojkymoY(stka, ww, hh, dd):
	proj = [] 
	for i in range(hh):
		maxval = 0
		for j in range(dd):
			for k in range(ww):
				curval = stka[j][ret1Dpos(ww, k, i)]
				curval = s2u8bit(curval)
				if maxval < curval:
					maxval = curval
		proj.append(maxval)
	return proj

# xz max projection to y-axis.  
#stka array of 1D arrays (1D stack)
def maxprojkymoZ(stka, ww, hh, dd):
	proj = [] 
	for i in range(dd):
		maxval = 0
		for j in range(hh):
			for k in range(ww):
				curval = stka[i][ret1Dpos(ww, k, j)]
				curval = s2u8bit(curval)
				if maxval < curval:
					maxval = curval
		proj.append(maxval)
	return proj

# grab hyperstack	
imp = IJ.getImage()
timepoints = imp.getNFrames() 
# extract single time point
#kymoimp = ImagePlus("kymo", ByteProcessor(ww, 1, )
kymoXA = []
kymoYA = []
kymoZA = []
for i in range(timepoints):
	e4d = Extractfrom4D()
	e4d.setGstarttimepoint(i+1)
	IJ.log("current time point" + str(i+1))
	aframe = e4d.coreheadless(imp, 3)
	stka = aframe.getImageStack().getImageArray()
	#stka = map(s2u8bit, stkas)
	outXA = maxprojkymoX(stka, aframe.getWidth(), aframe.getHeight(), aframe.getStackSize())
	kymoXA = kymoXA + map(u2s8bit, outXA)
	outYA = maxprojkymoY(stka, aframe.getWidth(), aframe.getHeight(), aframe.getStackSize())
	kymoYA = kymoYA + map(u2s8bit, outYA)	
	outZA = maxprojkymoZ(stka, aframe.getWidth(), aframe.getHeight(), aframe.getStackSize())
	kymoZA = kymoZA + map(u2s8bit, outZA)		

kymoXip = ByteProcessor(imp.getWidth(), imp.getNFrames(), kymoXA, GenByteColormode())
kymoYip = ByteProcessor(imp.getHeight(), imp.getNFrames(), kymoYA, GenByteColormode())
kymoZip = ByteProcessor(imp.getNSlices(), imp.getNFrames(), kymoZA, GenByteColormode())

outXimp = ImagePlus("YZprojection", kymoXip)
outXimp.show()
outYimp = ImagePlus("XZprojection", kymoYip)
outYimp.show()
outZimp = ImagePlus("XYprojection", kymoZip)
outZimp.show()
