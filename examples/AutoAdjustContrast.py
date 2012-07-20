#from ij.measure import Calibration
# re-implementation of "auto adjust contrast" in ImageJ by Jython
# Kota Miura (miura@embl.de)
# 20120515

autothreshold = 0
AUTO_THRESHOLD = 5000

imp = IJ.getImage()
cal = imp.getCalibration()
imp.setCalibration(None)
stats = imp.getStatistics() # get uncalibrated stats
imp.setCalibration(cal)
limit = int(stats.pixelCount/10)
histogram = stats.histogram #int[]
if autoThreshold<10:
	autoThreshold = AUTO_THRESHOLD
else:
	autoThreshold /= 2
threshold = int(stats.pixelCount/autoThreshold)	#int
i = -1
found = False
count = 0 # int
while True:
	i += 1
	count = histogram[i]
  if count>limit:
    count = 0
		found = count> threshold
#	if !found and i<255:
    if 0 not in (found, i>=255):
      break
hmin = i #int
print hmin

#i = 256;
#do {
  #i--;
  #count = histogram[i];
  #if (count>limit) count = 0;
  #found = count > threshold;
  #} while (!found && i>0);
#int hmax = i;
#Roi roi = imp.getRoi();
#if (hmax>=hmin) {
  #if (RGBImage) imp.killRoi();
  #min = stats.histMin+hmin*stats.binSize;
  #max = stats.histMin+hmax*stats.binSize;
  #if (min==max)
  #{min=stats.min; max=stats.max;}
  #setMinAndMax(imp, min, max);
  #if (RGBImage && roi!=null) imp.setRoi(roi);
  #} else {
      #reset(imp, ip);
      #return;
		}
