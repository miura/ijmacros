# rotate stack around x, y, or z with any angle. 
# initially made for rotating 90 degrees in each direction. 
# only functions, so it should be used by another script
# Kota Miura (miura@embl.de) 20120418

from ij import ImageStack
from ij import ImagePlus
import math
from mpicbg.models import AffineModel3D 
import mpicbg.models as mpimodel
import mpicbg.ij.stack.InverseTransformMapping as InverseTransformMapping
import java.lang.reflect as jarray
import java.lang.Float as Float

def ReCalcStackSize(transM, minA, maxA):
   transM.estimateBounds(minA, maxA);
   newsizeA = [0.0, 0.0, 0.0]  
   for i in range(len(newsizeA)): 
      newsizeA[i] = math.ceil(maxA[i] - minA[i])
   return minA, maxA, newsizeA
   
def ReCalcOffset(transM, minA):
  shift = mpimodel.TranslationModel3D()
  shift.set( -1*minA[0], -1*minA[1], -1*minA[2] )
  transM.preConcatenate(shift)

# this function takes input image stack and outputs rotated stack. 
# 20120418 Kota
# imp: ImagePlus
# axis: x:0, y:1, z:2
# radian: rotation in radian
def rotateStack(imp, axis, radian):
   modelM = AffineModel3D()
   modelM.rotate(axis, radian)
   print 'model: ', modelM.toString()
   ww  = imp.getWidth()
   hh  = imp.getHeight()
   dd  = imp.getImageStackSize()
   mapping = InverseTransformMapping( modelM );

   minA = jarray.Array.newInstance(Float.TYPE, 3)
   maxA = jarray.Array.newInstance(Float.TYPE, 3)
   minA[0] = 0.0
   minA[1] = 0.0
   minA[2] = 0.0
   maxA[0] = ww-1
   maxA[1] = hh-1
   maxA[2] = dd-1
   minA, maxA, destsizeA = ReCalcStackSize(modelM, minA, maxA)
   print destsizeA[0], destsizeA[1], destsizeA[2]
   nww = int(destsizeA[0])
   nhh = int(destsizeA[1])
   ndd = int(destsizeA[2])

   ReCalcOffset(modelM, minA)
   print 'recalculated model: ', modelM.toString()

   ip =  imp.getStack().getProcessor( 1 ).createProcessor( 1, 1 ) 
   target = ImageStack(nww, nhh)
   for s in range(ndd): 
      ip = ip.createProcessor(nww, nhh) 
      mapping.setSlice( s +  1) 
      mapping.mapInterpolated( imp.getStack(), ip ) 
      target.addSlice( "", ip ) 

   impout = ImagePlus("out", target)
   return impout
   
