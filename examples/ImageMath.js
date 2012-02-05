//Example Javascript for Background substraction using ImageMath 
// Kota Miura (miura@embl.de)

//get ImagePlus of the active window
imp = IJ.getImage();

//duplicate and blurr images
blurrimp = imp.duplicate();
IJ.run(blurrimp, "Gaussian Blur...", "sigma=15 stack");

//subtract the blurred from the original
ic = new ImageCalculator();
for (var i=1; i<=imp.getStackSize(); i++){
	imp.setSlice(i);
	blurrimp.setSlice(i);
	ic.run("Subtract", imp, blurrimp);
}


