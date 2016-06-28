import jarray as ja
from java.awt import Color

# http://weka.sourceforge.net/doc.dev/weka/estimators/KernelEstimator.html
from weka.estimators import KernelEstimator as KE

'''
Histogram based on kernel estimates

maybe add Apache based interpolation:

UnivariateInterpolator interpolator = new SplineInterpolator();
UnivariateFunction function = interpolator.interpolate(x, y);
double interpolationX = 0.5;
double interpolatedY = function.evaluate(x);
System.out println("f(" + interpolationX + ") = " + interpolatedY);

'''

def CDF(hist):
	cdf = []
	val = 0
	for p in hist:
		val += p
		cdf.append(val)
	return cdf
http://weka.sourceforge.net/doc.dev/weka/estimators/KernelEstimator.html
imp = IJ.getImage()
hist = imp.getProcessor().getHiUnivariateInterpolator interpolator = new SplineInterpolator();
UnivariateFunction function = interpolator.interpolate(x, y);
double interpolationX = 0.5;
double interpolatedY = function.evaluate(x);
System.out println("f(" + interpolationX + ") = " + interpolatedY);
#cdf = CDF(hist)
#print cdf

pixs = imp.getProcessor().getPixels()
print 'max:',max(pixs)
print 'min:',min(pixs)

ke = KE(1)
#for p in hist:
#	ke.addValue(p, 1)
#print "Num kernels", ke.getNumKernels()

if imp.getBitDepth() == 8:
	pypix = [p & 0xff for p in pixs]
elif imp.getBitDepth() == 16:
	pypix = [p & 0xffff for p in pixs]
else:
	pypix = pixs

print 'pymax:',max(pypix)
print 'pymin:',min(pypix)

		
for p in pypix:
#	if p < 0:
#		ke.addValue(p + 256, 1)
#	else:
	ke.addValue(p, 1)

xdata = [ i/2.0 for i in range(0, 2*max(pypix))]
estHist = []
for x in xdata:
	estHist.append(ke.getProbability(x))

jxdata = ja.array(xdata, 'd')
jestHist = ja.array(estHist, 'd')

estCDF = CDF(estHist)

pl = Plot("Hist", "Pixels", "Count", jxdata, jestHist)
pl.setLimits(0, max(pypix), 0, max(jestHist)*1.1) 
pl.setColor(Color.RED) 
#pl.addPoints(jxdata, ja.array(fity, 'd'), Plot.DOT )
pl.show()

cdfpl = Plot("CDF", "Pixels", "Cum Count", jxdata, ja.array(estCDF, 'd'))
cdfpl.setLimits(0, max(pypix), 0, max(estCDF)*1.1) 
cdfpl.setColor(Color.RED) 
#pl.addPoints(jxdata, ja.array(fity, 'd'), Plot.DOT )
cdfpl.show()
 
