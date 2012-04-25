# use of rotatestack.py by appending it to the path
from sys import path
import math

path.append('.')
import rotatestack

imp = IJ.getImage()
impout = rotatestack.rotateStack(imp, 0, math.pi/2)
impout.show()
