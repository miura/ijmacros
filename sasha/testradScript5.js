imp = IJ.getImage();
dd = ProfileAnalysis(imp);

function ProfileAnalysis(imp){
	rp =  IJ.runPlugIn(imp, "Radial_ProfileV2", "x=100.0 y=100.0 radius=100.0 noplot");
	IJ.log(rp.toString());
	var data = rp.getAccumulator();
	for (var i = 0; i<data[0].length; i++){
		IJ.log(data[0][i] +": sampled pixels:" + data[2][i]+ " mean value:" + data[1][i]);	
	}
	return data;
}