# Zprojects 4D image files (tiff series) and 
# save the resuted stack under separate folders within a meta folder
#
# works from command line, intended to be used in server - data storage. 
# input: arg1 = path to the meta folder
# 	arg2 = channel string "C01" or "C02"
# output: a 2D time series under meta folder.
# example commandline
#
# 	fiji --headless /g/cmci/Scripts/zproj_TifSeries_headless.py /<path>/folder C01
# 	fiji --headless /g/cmci/Scripts/zproj_TifSeries_headless.py /<path>/folder /path/to/save C01
# 
# Kota Miura (miura@embl.de) 
# 20110922 first version (for Li-Kun's data)
# 20120207 renamed the file from k_zprojector to zproj_TifSeries_headless

import sys
from java.io import File as JFile
import ij.IJ as IJ
import ij.ImageStack as ImageStack
import ij.ImagePlus as ImagePlus
import ij.plugin.ZProjector as ZProjector

def createStackImp(imp):
	ims = ImageStack(imp.getWidth(), imp.getHeight())
	ims.addSlice("0", imp.getProcessor())
	simp = ImagePlus("2D", ims)
	return simp

def importAChannle(path, chstr):
	dir = JFile(path)
	filesA = dir.list()
	sp = JFile.separator
	filesL = filesA.tolist()
	filesL.sort()
	simp = None
	for idx, i in enumerate(filesL):
		if i.startswith("._") != 1:
			if i.find(chstr) > -1:
#				IJ.log(str(idx))
				imp = IJ.openImage(path + sp + i)
#				print str(imp.getWidth())
				if simp == None:
					simp = createStackImp(imp)
				else:
					simp.getStack().addSlice(str(idx), imp.getProcessor())
#				print str(idx)+ ": " +  i
	return simp
					


def maxZprojection(stackimp):
	zp = ZProjector(stackimp)
	zp.setMethod(ZProjector.MAX_METHOD)
	zp.doProjection()
	zpimp = zp.getProjection()
	return zpimp

def metaFolders(ppath, chstr):
	dirc = JFile(ppath)
	print dirc
	filesA = dirc.list()
	
	sp = JFile.separator
	filesL = filesA.tolist()
	filesL.sort()
	projsimp = None
	for idx, i in enumerate(filesL):
		path = ppath + sp + i
		pathcheck = JFile(path)
		if pathcheck.isDirectory(): 
			stackimp = importAChannle(path, chstr)
			zpstackimp = maxZprojection(stackimp)
			if projsimp == None:
				projsimp = createStackImp(zpstackimp)
			else:
				projsimp.getStack().addSlice("T" + str(idx), zpstackimp.getProcessor())
			print "--- TimePoint" + str(idx)+ " max Zprojection added ---"
	return projsimp
		
	
#path = "Z:/likun/10uM rapa 1h_e1 caudal fin/T00001"
#ppath = "Z:/likun/10uM rapa 1h_e1 caudal fin"

#ppath = "/g/cmci/likun/10uM_rapa_1h_e1_caudal_fin"
#chstr = "C01"

ppath = sys.argv[1] 	
spath = sys.argv[2]
chstr = sys.argv[3]
sp = JFile.separator 	
zproimp = metaFolders(ppath, chstr)
IJ.saveAs(zproimp, "Tiff", spath + sp + "zproj"+chstr+".tif")

			
