importClass(Packages.emblcmci.glcm.GLCMtexture);
importClass(Packages.java.util.HashMap)
	gl = GLCMtexture();
	gl.d = 10;	//gap distance
	gl.phi = 0;
	gl.rt_reset = false;
	imp = IJ.getImage();
	var ip = imp.getStack().getProcessor(1);
	glcmA = gl.calcGLMC(ip);	
	//gl.setglcm(glcmA);
	//gl.writetoResultsTable(true);

	IJ.log(gl.getCorrelation());
	map = gl.getResultsArray();
	javamap = HashMap(map);
	IJ.log(javamap.get("Correlation"));
	IJ.log(javamap.get("Energy"));
	IJ.log(gl.getEnergy());	