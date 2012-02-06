import ij.IJ as IJ

imp = IJ.getImage()
slices = imp.getStackSize()
#ip = imp.getStack().getProcessor(1)
#pix = ip.getPixels()
#print str(pix[100])
imp1 = Duplicator().run(imp)
imp2 = Duplicator().run(imp)
imp1.getStack().deleteSlice(slices)
imp1.getStack().deleteSlice(slices-1)
imp2.getStack().deleteSlice(2)
imp2.getStack().deleteSlice(1)
 
ic = ImageCalculator()
impsum = ic.run("Add create stack", imp1, imp2)

IJ.run(impsum, "Divide...", "value=2 stack");
impsum.getStack().addSlice("dummy", ShortProcessor(imp.getWidth(), imp.getHeight()))
impsum.getStack().addSlice("dummy", ShortProcessor(imp.getWidth(), imp.getHeight()), 1)
#impsum.show()	

impout = ic.run("Subtract create stack", imp, impsum)
impout.show()
	
	