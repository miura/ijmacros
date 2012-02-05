# this script runs on hyperstack. 

from loci.plugins.macro import LociFunctions as LociFunctions
from loci.plugins import BF
from ij.plugin import ZProjector as ZP
import os

#LF = LociFunctions()
#this line opens image in desk top automatically. 
#should be suprressed. 
#imp = LF.openImagePlus('/Users/miura/Documents/people/mayumi/Nnf1_scsi_4.lsm')

# second method

# multi-channel single time point example
filepath = '/Users/miura/Documents/people/mayumi/Nnf1_scsi_4.lsm'
filedir = '/Users/miura/Documents/people/mayumi/'
# 4D hyperstack example. 
#filepath = '/Users/miura/Documents/people/Dirk/PU1-NBT-3dpf-30min-gfp-only.tif'

def zproject(fpath):
	impA = BF.openImagePlus(filepath)
	#impA = BF.openImagePlus()
	print len(impA)
	#this actually imports a hyperstack. 
	#impA[0].show()
	zpimp = ZP()
	print "Channels" + str(impA[0].getNChannels())
	print "Z slices:" + str(impA[0].getNSlices())
	print "Frames:" + str(impA[0].getNFrames())
	zpimp.setImage(impA[0])
	zpimp.setMethod(zpimp.MAX_METHOD)
	zpimp.setStartSlice(1)
	zpimp.setStopSlice(impA[0].getNSlices())
	zpimp.doHyperStackProjection(True)
	zpedimp = zpimp.getProjection()
	return zpedimp

filelist = os.listdir(filedir)
for afile in filelist:
	if afile.lower().endswith('.lsm'):
		print afile
outimp = zproject(filepath)
outimp.show()

