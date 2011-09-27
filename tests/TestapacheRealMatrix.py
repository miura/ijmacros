from org.apache.commons.math.linear import ArrayRealVector as arv
from org.apache.commons.math.linear import Array2DRowRealMatrix as am
from jarray import array
import math

from java.awt.geom import AffineTransform as AT
import java.awt.geom.Point2D.Double as pnt
 
#vec = java.lang.reflect.Array.newInstance(java.lang.Double.TYPE, 2);
#vec[0] = 2.0;
#vec[1] = 3.0;

def rotateVec(vx, vy, rotation):
	av = am(2, 1)
	av.setEntry(0 ,0 , vx)
	av.setEntry(1, 0, vy)

#	dd = [2.0, 6,0]
#	jdd = array(dd, 'd')	
#	bv = am(jdd) 

	rot = rotation
	mat = am(2, 2)
	mat.setEntry(0, 0, math.cos(rot))
	mat.setEntry(0, 1, -1 * math.sin(rot))
	mat.setEntry(1, 0, math.sin(rot))
	mat.setEntry(1, 1, math.cos(rot))
	#print mat.getData()
	avdash = mat.multiply(av)
	return avdash

#rotvec  = rotateVec(1, 1, math.pi/4)
#print rotvec.getData()

roter = AT.getRotateInstance(math.pi/4, 0, 0)
sp = pnt(1, 1)
dp = pnt()
roter.deltaTransform(sp, dp)
print dp.x
print dp.y
 

 

