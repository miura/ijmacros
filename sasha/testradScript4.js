//importClass(Packages.emblcmci.radial.RadialProfile);
//importClass(Packages.Radial_ProfileV2);
//importPackage(Packages.emblcmci.radial);
//works with fiji, but not in ImageJ
imp = IJ.getImage();

slices = imp.getNSlices();
for (var i = 0; i < slices; i++){
	imp.setSlice(i+1);
	data = ProfileAnalysis(imp);
}

function ProfileAnalysis(imp){
	rp =  IJ.runPlugIn(imp, "Radial_ProfileV2", "x=127.50 y=127.50 radius=127.50 noplot");
	var data = rp.getAccumulator();
	for (var i = 0; i<data[0].length; i++){
		IJ.log(data[0][i] +": "+ data[1][i]);	
	}
	return data;
}
