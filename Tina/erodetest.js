imgpath = "/g/almf/miura/Tina/"; //unix
filename = "110608wt2.tif.proc.tif";
filename = "seg2frames.tif"; //test
savefilename = filename + ".eroded.tif";

//imporg = IJ.getImage();
imporg = IJ.openImage(imgpath + filename);

imperode = imporg.duplicate();
/*
IJ.run(imperode, "Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
//IJ.run(imperode, "Options...", "iterations=1 count=1 edm=Overwrite do=Nothing");
for (var i = 0; i < 3; i++){
//	for (var j = 1; j <= imperode.getStackSize(); j++){
//		imperode.setSlice(j);
		//IJ.run(imperode, "Erode", "stack");
		IJ.run(imperode, "Dilate", "stack");
//	}
}
IJ.run(imperode, "Invert", "stack");
IJ.run(imperode, "Watershed", "stack");
IJ.run(imperode, "Invert", "stack");
*/
IJ.run(imperode, "Invert", "stack"); //need this in Unix
for (var i = 0; i < 2; i++){
    IJ.run(imperode, "Erode", "stack"); // in unix, need inversion
	//IJ.run(imperode, "Dilate", "stack"); 
}
IJ.run(imperode, "Watershed", "stack");
IJ.run(imperode, "Invert", "stack"); //need this in Unix

IJ.saveAs(imperode, "Tiff", imgpath + savefilename);
