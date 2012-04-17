# create difference image from the current stack. 
imp = IJ.getImage()
if imp.getStackSize() > 1:
	impdup1 = Duplicator().run(imp)
	impdup2 = Duplicator().run(imp)
	impdup1.getStack().deleteSlice(imp.getStackSize())
	impdup2.getStack().deleteSlice(1)
	impsub = ImageCalculator().run("Subtract create 32-bit stack", impdup1, impdup2)
	impsub.show()
