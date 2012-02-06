importClass(Packages.emblcmci.radial.RadialProfile);
//importClass(Packages.Radial_ProfileV2);
//importPackage(Packages.emblcmci.radial);
//works with fiji, but not in ImageJ
imp = IJ.getImage();
//rp =  IJ.runPlugIn(imp, "Radial_ProfileV2", "x=100.0 y=100.0 radius=100.0 noplot");
rp = new RadialProfile();
//rp.setup("x=100.0 y=100.0 radius=100.0 noplot", imp);
//rp.setVars(100.0, 100.0, 100.0, false, false);
//rp.setup("", imp)
rp.doit(imp,"x=100.0 y=100.0 radius=100.0");


//radius = rp.getRadius();

data = rp.getAccumulator();
for (var i = 0; i<data[0].length; i++){
	IJ.log(data[0][i] +": datapnts:"+ data[2][i]+ " Intensity" +data[1][i] );	
}
/*
outp = "";
for (var i = 0; i < radius.length; i++){
	for (var j = 0; j<radius[0].length; j++){
		outp = outp + radius[i][j] + "\t";
	}
	outp = outp + "\n";
}
*/
//IJ.log(outp);
	
//IJ.log(rp.getRadius()[100][100]);
