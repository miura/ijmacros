//BandPassTester.js
/*
	- vary bandpass parameter to get optimum filter.
*/
fmin = 1;
fmax = 10;
stepsize = 1;

fl = 20;

imp = IJ.getImage();
is = ImageStack(imp.getWidth(), imp.getHeight());
is.addSlice("original", imp.getProcessor().duplicate());
impd = ImagePlus("BandPassTest", is);
for(i =fmin; i <= fmax; i+=stepsize){
	op = "filter_large=" + fl + " filter_small=" +i+ " suppress=None tolerance=5 autoscale saturate";
	impc = Duplicator().run(imp);
	IJ.run(impc,"Bandpass Filter...", op);
	impd.getStack().addSlice("filtermin"+i, impc.getProcessor());
	//impc.flush();
}
impd.show();