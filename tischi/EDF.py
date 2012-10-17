from edfgui import ExtendedDepthOfField
from edfgui import Parameters


imp = WindowManager.getCurrentImage()
# or imp = IJ.openImage(...)

parameters = Parameters()
#  "quality='1' topology='0' show-view='on' show-topology='off'"
quality = 1
topology = 0
showview = True
showtopology= False
parameters.setQualitySettings(quality)
parameters.setTopologySettings(topology)
parameters.show3dView = showview 
parameters.showTopology = showtopology

if imp == None:
	IJ.error("The input image is not a z-stack of images.")
else:
	if imp.getType() == ImagePlus.COLOR_RGB:
            parameters.outputColorMap = Parameters.COLOR_RGB
	edf = ExtendedDepthOfField(imp, parameters)
	edf.process()
	imp.show()