from de.embl.cmci.radial import RadialProfile

def radMeasure(rp, rt, slicenum):
	imp.setSlice(slicenum)
	rp.doit(imp, "")
	data = rp.getAccumulator()
	for d in data:
		print d
	index = data[0]
	intensity = data[1]
	header1 = 'index' + str(slicenum)
	header2 = 'intensity' + str(slicenum)
	for i, ind in enumerate(index):
		rt.setValue(header1, i, float(index[i]))
		rt.setValue(header2, i, float(intensity[i]))
		rt.incrementCounter() 
		
imp = IJ.getImage()
rp = RadialProfile()
#setVars(double x0, double y0, double mr, boolean usecalib, boolean doplot)
rp.setVars(100.0, 100.0, 100.0, False, False)
rt = ResultsTable()
radMeasure(rp, rt, 1)
rt.show("Results")
	 