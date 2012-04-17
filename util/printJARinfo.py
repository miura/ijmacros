# JAR info tool
# priting out Manifest File informatin
# Kota Miura (miura@embl.de)
# 20120417

from java.util.jar import JarFile
#from java.util.jar import Manifest
def printClasses(jf):
	for e in jf.entries():
		print e.getName()

def printManifest(jf):
	mf = jf.getManifest()
	if mf is not None:
		mainatt = mf.getMainAttributes()
		keys = mainatt.keySet()
		for i in keys:
			print i, mainatt.getValue(i)
	else:
		print 'pity, No Manifest File found!'

# main
filepath = 'C:\\ImageJ2\\plugins\\CLI_.jar'
filepath = 'C:\\ImageJ2\\plugins\\AutoThresholdAdjuster3D_.jar'
filepath = 'D:\\gitrepo\\CorrectBleach\\CorrectBleach_.jar'
jf = JarFile(filepath)
printManifest(jf)
jf.close()
