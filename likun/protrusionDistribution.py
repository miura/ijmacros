# protrusionDistribution
# Kota Miura (miura@embl.de)
# requires 	(1) opened results table with centroid coordinates
#		(2) difference image
# for each frame, detects pixels with -255 (decrease in area) and with +255 (increase in area)
# and measures its position relative to the movement vector between that frame and the next frame. 
# outputs data as a list of numbers, [frame, angle].
# angle is between -pi and pi, negative being counter clockwise. 

from org.apache.commons.math.geometry.euclidean.threed import Vector3D
from ij.measure import ResultsTable
import math
import csv

def returnAngle(refVec, thisVec):
	rad = Vector3D.angle(refVec, thisVec)
	crosspV = Vector3D.crossProduct(refVec, thisVec)
	if crosspV.getZ()<0:
		rad = rad* -1
	return rad

def returnVecArray(ip):
	ww = ip.getWidth()
	pix = ip.getPixels()
	vAplus = []
	vAminus = []
	for i in range(len(pix)):
		if not pix[i]==0:
			xpos = math.floor(i%ww)
			ypos = math.floor(i/ww)
#			print repr(i).ljust(5), repr(xpos).ljust(5), repr(ypos).ljust(5), repr(pix[i]).ljust(5)
			if pix[i] > 0:
				vAplus.append(Vector3D(xpos, ypos, 0))
			else:
				vAminus.append(Vector3D(xpos, ypos, 0))
	return vAplus, vAminus


# get data from results table. 
rt = ResultsTable.getResultsTable()
xcoords = rt.getColumnAsDoubles(rt.getColumnIndex("X"))
ycoords = rt.getColumnAsDoubles(rt.getColumnIndex("Y"))
centvecs = []
for idx, i in enumerate(xcoords):
#	print i
	centvecs.append(Vector3D(i, ycoords[idx], 0))
movevecs = []	
for i in range(0, len(centvecs)-1):
	movevecs.append(Vector3D(1, centvecs[i+1], -1, centvecs[i]))
#	print repr(movevecs[i].getX()).ljust(5),
#	print repr(movevecs[i].getY()).ljust(5) 
#	rt.setValue("mx", i, movevecs[i].getX())
#rt.updateResults()

imp = IJ.getImage()
incAA = []
decAA = []
for i in range(1, imp.getStackSize()+1): 
	ip = imp.getStack().getProcessor(i)
	print "Frame", repr(i).rjust(3)
	Vincrease, Vdecrease = returnVecArray(ip)
	incA = []
	decA = []
	for v in Vincrease:
		rad = returnAngle(movevecs[i-1], Vector3D(1, v, -1, centvecs[i-1]))
		incA.append(rad)
	for v in Vdecrease:
		rad = returnAngle(movevecs[i-1], Vector3D(1, v, -1, centvecs[i-1]))
		decA.append(rad)
	print len(incA)
	print len(decA)
	incAA.append(incA)
	decAA.append(decA)

print len(incAA)
print len(decAA)

try:
	savedir = 'Z:/likun/e1cell1/'
	file1 = open(savedir + 'inc.csv', 'wb')
	incfile = csv.writer(file1, delimiter='\t')
	for idx, perframe in enumerate(incAA):
		for j in perframe:
			incfile.writerow([repr(idx), repr(j)])

	file2 = open(savedir + 'dec.csv', 'wb')
	decfile = csv.writer(file2, delimiter='\t')
	for idx, perframe in enumerate(decAA):
		for j in perframe:
			decfile.writerow([repr(idx), repr(j)])
finally:
	file1.close()
	file2.close()

#	print len(Vindrease)
#	print len(Vdecrease)

#v1 = Vector3D(1, 0, 0)
#v2 = Vector3D(-1, 1, 0)
#	print Vector3D.angle(v1, v2)
#	print returnAngle(v1, v2)

