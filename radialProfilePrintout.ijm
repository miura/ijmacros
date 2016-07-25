pyscript = "" +
"from ij import IJ" + "\n" +
"imp = IJ.getImage()" +"\n" +
"pwin = imp.getWindow()" +"\n" +
"xvalues = pwin.getXValues()" +"\n" +
"yvalues = pwin.getYValues()" +"\n" +
"for i, v in enumerate(xvalues):" +"\n" +
"	print v, '\t', yvalues[0][i]";

run("Blobs (25K)");
run("Radial Profile Angle", "x_center=127.50 y_center=127.50 radius=127.50 starting_angle=0 integration_angle=180");
eval("python", pyscript);