from edfgui import ExtendedDepthOfFieldHeadless
from edfgui import Parameters

imp = IJ.getImage()
edf = ExtendedDepthOfFieldHeadless(imp, Parameters())
edf.testprint()