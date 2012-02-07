# this script runs on directory containing .lif files
# creates zprojected tiff stacks for all files in lif-grouped files. 
# destination is the same directory, a directory for each lif file is created
# and all image files in that lif file will be z projected and saved under the directory.  
# Kota Miua (miura@embl.de)
# 20120206 ver 1.0
#
# commandline example: single argument, a source directory
# fiji zproj_LIF_headelss.py /g/cmci/test/

from loci.plugins.macro import LociFunctions as LociFunctions
from loci.plugins import BF
from loci.plugins.in import ImporterOptions as IO
from ij.plugin import ZProjector as ZP
from ij.io import FileSaver
import os, sys
from os.path import splitext
from java.io import File, FilenameFilter
from ij.util import Tools as ijtool

#LF = LociFunctions()
#this line opens image in desk top automatically. 
#should be suprressed. 
#imp = LF.openImagePlus('/Users/miura/Documents/people/mayumi/Nnf1_scsi_4.lsm')

# second method

# multi-channel single time point example
filepath = '/Users/miura/Documents/people/mayumi/Nnf1_scsi_4.lsm'
filepath = '/g/cmci/test/Exp07_abTest_20120130.lif'
#filepath = '/Users/miura/Desktop/Exp07_abTest_20120130.lif'
filedir = '/Users/miura/Documents/people/mayumi/'
filedir = '/g/cmci/'
#filedir = '/Users/miura/Desktop/'
# 4D hyperstack example. 
#filepath = '/Users/miura/Documents/people/Dirk/PU1-NBT-3dpf-30min-gfp-only.tif'

def getImps(fpath):
	opt = IO()
	opt.setId(fpath)
	opt.setOpenAllSeries(True) 
	impA = BF.openImagePlus(opt)
	print "Series number: " + str(len(impA))
	#impA = BF.openImagePlus()
	return impA
	
def printInfo(impA):
	for item in impA:	
		#this actually imports a hyperstack. 
		#impA[0].show()
		print "Image Title: " + item.getTitle()
		print "Channels: " + str(item.getNChannels())
		print "Z slices: " + str(item.getNSlices())
		print "Frames:" + str(item.getNFrames())
def zproj(imp):
	zpimp = ZP()
	zpimp.setImage(imp)
	zpimp.setMethod(zpimp.MAX_METHOD)
	zpimp.setStartSlice(1)
	zpimp.setStopSlice(imp.getNSlices())
	zpimp.doHyperStackProjection(True)
	zpedimp = zpimp.getProjection()
	return zpedimp
class Filter(FilenameFilter):
  def accept(self, folder, name):
    return not File(folder.getAbsolutePath() + "/" + name).isHidden()
    	
def validate(target_folder):
  f = File(target_folder)
  if len(File(target_folder).list(Filter())) > 1:
     print "there are some files already in the target folder, terminates the processing."
     return False
     	
def getArg():
  if len(sys.argv) < 2:
    print "Usage: fiji <script-name> <dir path>"
    sys.exit(1) 
  target_folder = sys.argv[1]
  if target_folder is None:
    print "no target folder"
    return filedir
#  if not validate(target_folder):
#    return filedir
  return target_folder

filedir = getArg()   
filelist = os.listdir(filedir)
for afile in filelist:
	if afile.lower().endswith('.lif'):
		print filedir
		print "..." + afile
		filebase = splitext(afile)[0]
		imps = getImps(filedir+afile)
		printInfo(imps)	
		for (counter, item) in enumerate(imps):
			outimp = zproj(item)
			#outname = filedir + filebase + "/" + "s" + str(counter) + ".tif"
			subname = ijtool.split(item.getTitle(), " - ")[1]
			outname = filedir + filebase + "/" + subname + "_ZP.tif"
			if not os.path.isdir(filedir + filebase):
				os.mkdir(filedir + filebase)
			fs = FileSaver(outimp)
			fs.saveAsTiffStack(outname)
			
#outimp = zproject(filepath)
#outimp.show()

