'''
Convert grid position coordinates for each image file in ScanR metadata 
to Preibisch stitching plugin format.

A jython code, intended to run in Fiji. 

on request from Luca and Sabine

Kota Miura (miura@embl.de) 
20160218 
'''
import os, re
from ij.io import DirectoryChooser

#rootDir = "/Users/miura/Dropbox/examples/empty_001"
rootDir = DirectoryChooser("Converter:\nChoose the folder of acquired Data").getDirectory()
dataDir = os.path.join(rootDir, "data")
metadatapath = os.path.join(rootDir, "AcquisitionLog.dat")
outdatapath = os.path.join(dataDir, "TileConfiguration.txt")

def addPreamble(target):
	target.write('# Define the number of dimensions we are working on\n')
	target.write('dim=2\n')
	target.write('\n')
	target.write('# Define the image coordinates')

def getXYcoords(thefile, position):
	linepattern = re.compile('(.*)P='+ position + '\tT=(.*)\tIMAGEX=(.*)\tIMAGEY=(.*)\tIMAGEZ=(.*)')
	print "p =", position
	for i, line in enumerate(thefile):
		res = re.search(linepattern, line)
		if res:
			return res.group(3), res.group(4)

def loopFiles(dataDir, target):
	pattern = re.compile('(.*)--W(.*)--P(.*)--Z(.*)--T(.*)--(.*)\.(.*)')		
	for root, directories, filenames in os.walk(dataDir):
		for filename in filenames:
			if not filename.endswith(".tif"):
				continue
			res = re.search(pattern, filename)
			basename = res.group(1)
			spot = res.group(2)
			position = res.group(3)
			zpos = res.group(4)
			tpos = res.group(5)
			imgtype = res.group(6)
			filetype = res.group(7)
			
			xcoord, ycoord = getXYcoords(f, str(int(position)))
#			output = os.path.join('data', filename) + '; ; (' + xcoord +', '+ ycoord + ')'
			output = os.path.join(filename) + '; ; (' + xcoord +', '+ ycoord + ')'
			print output
			target.write('\n' + output)

f = open(metadatapath)
target = open(outdatapath, 'w')

addPreamble(target)
loopFiles(dataDir, target)
f.close()
target.close()


# Define the number of dimensions we are working on
#dim = 2

# Define the image coordinates
#Seq0000_XY001.tif; ; (-17698.362892, -15767.803547)
#Seq0000_XY002.tif; ; (-19218.963165, -15620.600273)
#Seq0000_XY003.tif; ; (-20739.427012, -15473.396999)
