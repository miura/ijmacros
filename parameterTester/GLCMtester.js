importClass(Packages.emblcmci.glcm.GLCMtexture);
g = new GLCMtexture(IJ.getImage(), 1, 0, true, false);
glcm = g.calcGLCM();
ht = g.getResultsArray();
g.writetoResultsTable(true)
IJ.log(ht.get("Energy"));

IJ.log(glcm[10][10]);
//String line;
file_name = "d:\\temp\\outmatrix.txt";
file = new java.io.FileWriter(file_name);
out = new java.io.BufferedWriter(file);
toFile = new StringBuilder();
for (var i = 0 ;i < glcm[0].length;i++){
	for (var j = 0; j < glcm.length; j++){
		toFile.append(glcm[j][i]);
		toFile.append(", ");		
	}
	toFile.append("\n ");
}
out.write(toFile.toString());
out.close();