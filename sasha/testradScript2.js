//importClass(Packages.emblcmci.radial.RadialProfile);
importClass(Packages.Radial_ProfileV2);
//importPackage(Packages.emblcmci.radial);
//works with fiji, but not in ImageJ
imp = IJ.getImage();
rp = new Radial_ProfileV2();
//rp =  IJ.runPlugIn(imp, "emblcmci.radial.Radial_Profile", "x=127.50 y=127.50 radius=127.50 noplot");
//rp.setup("x=127.50 y=127.50 radius=127.50 noplot", imp);
//rp.setup("", imp)
//rp.setup("x=127.50 y=127.50 radius=127.50 noplot", imp);
rp.doit(imp,"x=127.50 y=127.50 radius=127.50");


//rp.run(imp.getProcessor());radius = rp.getRadius();

data = rp.getAccumulator();
for (var i = 0; i<data[0].length; i++){
	IJ.log(data[0][i] +": "+ data[1][i]);	
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
