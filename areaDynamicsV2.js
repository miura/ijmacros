importClass(Packages.ij.util.Tools);
importClass(Packages.ij.gui.Wand);
importClass(Packages.ij.gui.ShapeRoi);
importClass(Packages.emblcmci.tools.LevelSetExt);

imgpath = "/g/almf/miura/Tina/"; //unix
//imgpath = "Z:\\Tina\\"; //win
filename = "110608wt2.tif.proc.tif"; 
//filename = "seg2frames.tif"; //test
savefilename = filename + ".bin.tif";
imporg = IJ.openImage(imgpath + filename);
imperode = imporg.duplicate();

IJ.run(imperode, "Invert", "stack"); //need this in Unix
for (var i = 0; i < 2; i++){
    IJ.run(imperode, "Erode", "stack"); 
}
IJ.run(imperode, "Watershed", "stack");

var binstk = new ImageStack(imporg.getWidth(), imporg.getHeight());

for (var i = 1; i <= imperode.getStackSize(); i++){
    impdummy = ImagePlus("temp", imperode.getStack().getProcessor(i).duplicate());
    imporg1frame = ImagePlus("temporg", imporg.getStack().getProcessor(i).duplicate());

//locimp = IJ.getImage();
    rois = PrepareSeedV2(impdummy);
    impdummy.setRoi(rois, true);
    imporg1frame.setRoi(rois.clone(), true);
    impseg = doLevelSet(imporg1frame);
    binstk.addSlice(String(i), impseg.getProcessor());
    impdummy.flush();
    imporg1frame.flush();
}
binimp = ImagePlus("binarized", binstk);
//binimp.show();
IJ.saveAs(binimp, "Tiff", imgpath + savefilename);

function wandRoi(locimp, wandx, wandy){
   var locip = locimp.getProcessor();
   var wand = Wand(locip);
   var currentpix = locip.getPixel(wandx, wandy);
   var wandroi = null;
   if (currentpix == 255) {
      wand.autoOutline(wandx, wandy, currentpix, currentpix, wand.EIGHT_CONNECTED);
      var roiType = Roi.FREEROI;
      wandroi = new PolygonRoi(wand.xpoints, wand.ypoints, wand.npoints, roiType);
   }
   return wandroi;
}

function PrepareSeedV2(locimp){
	var rt = ResultsTable().getResultsTable();
	rt.reset();
	var paopt = ParticleAnalyzer.CLEAR_WORKSHEET
	+ ParticleAnalyzer.SHOW_MASKS 
	+ ParticleAnalyzer.INCLUDE_HOLES
	+ ParticleAnalyzer.EXCLUDE_EDGE_PARTICLES 
	+ ParticleAnalyzer.SHOW_RESULTS; 
//    + ParticleAnalyzer.ADD_TO_MANAGER
//Double.POSITIVE_INFINITY
	var measopt = ParticleAnalyzer.AREA
	+ ParticleAnalyzer.SHAPE_DESCRIPTORS
	+ ParticleAnalyzer.CENTROID;  
	var ptMinSize = 50;
	var ptMaxSize = 8500;
	var circMin = 0.1;
	var circMax = 1.0;
	var pa = new ParticleAnalyzer(paopt, measopt, rt, ptMinSize, ptMaxSize, circMin, circMax);
	pa.setHideOutputImage(true); 
	pa.analyze(locimp); 
//	var colheads = rt.getColumnHeadings();
//	IJ.log(colheads);
//	var colheadsA = Tools.split(colheads, "\t");
//	for (var i in colheadsA) IJ.log(""+ i + ": " + colheadsA[i]); //X is 2, Yis 3
	IJ.log("current rows in result table"+ rt.getCounter() );
	IJ.log("X column" + rt.getColumnIndex("X"));
	IJ.log("Y column" + rt.getColumnIndex("Y"));
  var xposA = rt.getColumn(rt.getColumnIndex("X")); 
  var yposA = rt.getColumn(rt.getColumnIndex("Y"));
//	var xposA = rt.getColumn(2); 
//	var yposA = rt.getColumn(3);
  
	IJ.log("xpos length" + xposA.length);
	var imp2 = pa.getOutputImage();
	//imp2.show();
	
	var s1 = null;
	var s2 = null;
	for (var i in xposA){
    	var aroi = wandRoi(imp2, xposA[i], yposA[i]);
   		IJ.log(""+ i + ":" + xposA[i]+ "," + yposA[i]);
    	if (aroi != null){
    		if (s1 == null)
     			s1 = ShapeRoi(aroi);
     		else {
       			s2 = ShapeRoi(aroi);
       			s1 = s1.or(s2);
     		}
		} else {
    		IJ.log("...object " + "not detected");
   		}
	}
  return s1;
}

function doLevelSet(imp){
//set parameters

	var useFastMarching = false;
	var useLevelSets = true;
	var greyValueThreshold = 4.0;  
	var distanceThreshold = 1.0;
	var advection = 40;
	var curvature = 2; 
	var propagation = 1;
	var grayscale = 30;
	var convergence = 0.0050;
	var inwards = false;
// parameter setting finished

//constructor of LevelSets with parameters
	var ls = new LevelSetExt(useFastMarching, useLevelSets, 
		distanceThreshold, greyValueThreshold, 
		advection, curvature, propagation, grayscale, convergence, 
		inwards);
//execution with current image imp
	var impout = ls.execute(imp, false); //arg[1] = false suppresses the display of progress image window
	return impout;
}
