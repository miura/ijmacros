from ij import IJ
imp = IJ.getImage()
pwin = imp.getWindow()
xvalues = pwin.getXValues()
yvalues = pwin.getYValues()
for i, v in enumerate(xvalues):
	print i, v, yvalues[0][i]