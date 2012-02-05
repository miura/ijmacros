# fitting profile using gaussian
# getting the half-max width
# 	http://hyperphysics.phy-astr.gsu.edu/hbase/math/gaufcn2.html

import ij.measure.CurveFitter

imp = IJ.getImage()
prof = ProfilePlot(imp)
curprofile = prof.getProfile()
print(len(curprofile));
#for i in curprofile:
#	print(i)

pixx = range(len(curprofile))
fitA = range(len(curprofile))

cf = CurveFitter(pixx, curprofile)
cf.doFit(cf.GAUSSIAN)
#print(cf.getFormula())
print(cf.getResultString())

cfp = cf.getParams()
EstimatedDiameter = "Diameter = " + str(2.355*cfp[3])
IJ.log(EstimatedDiameter)

for i in range(len(curprofile)):
	fitA[i] = cf.f(cfp, i)
fitplot = Plot("fitted", "pixels", "intensity", pixx, fitA)
fitplot.addPoints(pixx, curprofile, fitplot.CIRCLE)
fitplot.addLabel(0.1, 0.1, EstimatedDiameter)
fitplot.show()

