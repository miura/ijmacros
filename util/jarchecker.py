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
jarpath = '/Applications/ImageJ/plugins/PTA_.jar'
#jarpath = '/Applications/ImageJ/plugins/scala-library.jar'
#jarpath = '/Applications/ImageJ/plugins/test_scala.jar'
jarpath = '/Applications/ImageJ/plugins/test_scala.jar'
jarpath = '/Users/miura/Dropbox/codes/fiji/plugins/Jython_Interpreter-2.0.0-SNAPSHOT.jar'
print jarpath
jf = JarFile(jarpath)
printManifest(jf)