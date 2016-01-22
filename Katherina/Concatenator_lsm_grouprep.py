'''
Opens series of .lsm files as a single hyperstack

20130712 Kota Miura (cmci.embl.de)

Choose a file among the file series, and this script searchs all the 
files with a pattern

	(basename)_R(fixed)_GR(.*)_B(block number)_L(location number)\.lsm

with GR (group repetition) number being left to be variable, 
and then these files are merged in the orfer of the GR value. 

request from Katharina Sonnen
'''

import os
import re
from ij import ImagePlus
from ij import IJ
from ij.io import Opener
from ij.plugin import Concatenator
from jarray import array

srcpath = IJ.getFilePath('Choose the first file')
filename = os.path.basename(srcpath)
srcDir = os.path.dirname(srcpath)

#chosefile = '20130711_R1_GR001_B1_L2.lsm'
pattern = re.compile('(.*)_R(.*)_GR(.*)_B(.*)_L(.*)\.lsm')
res = re.search(pattern, filename)

basename = res.group(1)
repetition = res.group(2)
grouprepetition = res.group(3)
block = res.group(4)
location = res.group(5)

GRlist = []
for root, directories, filenames in os.walk(srcDir):
	for filename in filenames:
		match = re.search(pattern, filename)
		if match is not None:
			#print filename, match.group(3)
			GRlist.append(match.group(3))

print srcDir
print 'files: ', len(GRlist)

GRlist = sorted(GRlist)
timeseries = []

for timepoint in GRlist:
	thisfile = basename + '_R' + repetition + '_GR' + timepoint + '_B' + block + '_L' + location + '.lsm'
	print thisfile
	imp = Opener.openUsingBioFormats(os.path.join(srcDir, thisfile))
	imp.setOpenAsHyperStack(False)
	timeseries.append(imp)

newname = basename + '_R' + repetition + '_B' + block + '_L' + location + '.lsm'
calib = timeseries[0].getCalibration()
dimA = timeseries[0].getDimensions()
jaimp = array(timeseries, ImagePlus)
ccc = Concatenator()
#allimp = ccc.concatenateHyperstacks(jaimp, newname, False)
allimp = ccc.concatenate(jaimp, False)
allimp.setDimensions(dimA[2], dimA[3], len(GRlist))
allimp.setCalibration(calib)
allimp.setOpenAsHyperStack(True)
allimp.show()
	

#for mm in res.groups():
#	print mm


