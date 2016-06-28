import jarray as ja
from java.awt import Color

def CDF(hist):
	cdf = []
	val = 0
	for p in hist:
		val += p
		cdf.append(val)
	return cdf

imp = IJ.getImage()
hist = imp.getProcessor().getHistogram()
print hist
cdf = CDF(hist)
print cdf
jcdf = ja.array(cdf, 'd')
xdata = range(0, len(cdf))
jx = ja.array(xdata, 'd')


cfit = CurveFitter(xdata, cdf)
cfit.doFit(CurveFitter.POLY6)
cfitP = cfit.getParams()
fity = []
for ax in xdata:
	 fity.append(cfit.f(cfitP, ax))


pl = Plot("CDF", "Pixels", "Cumulative Count", jx, jcdf)
pl.setLimits(0, 256, 0, max(cdf)*1.1) 
pl.setColor(Color.RED) 
pl.addPoints(ja.array(xdata, 'd'), ja.array(fity, 'd'), Plot.DOT )
pl.show()
 


