# opens a single time point for specified channel
# 
# intended to be used from desktop
# Kota Miura (miura@embl.de)

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

path = "Z:/likun/10uM_rapa_1h_e1_caudal_fin/T00001"
chstr = "C01"
stackimp = importAChannle(path, chstr)
stackimp.show()
