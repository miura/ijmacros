//this version is not working. 

importClass(Packages.ij.util.Tools);
importClass(Packages.ij.gui.Wand);
importClass(Packages.ij.gui.ShapeRoi);

imgpath = "/g/almf/miura/Tina/"; //unix
imgpath = "Z:\\Tina\\"; //win
filename = "110608wt2.tif.proc.tif";
filename = "seg2frames.tif"; //test
savefilename = filename + ".bin.tif";

//imporg = IJ.getImage();
imporg = IJ.openImage(imgpath + filename);

imperode = imporg.duplicate();

for (var i = 0; i < 2; i++){
		IJ.run(imperode, "Erode", "stack"); //desktop, non inverted lut
		//IJ.run(imperode, "Dilate", "stack"); //unix
}

//IJ.run(imperode, "Invert", "stack");
IJ.run(imperode, "Watershed", "stack");
//IJ.run(imperode, "Invert", "stack");

var binstk = new ImageStack(imporg.getWidth(), imporg.getHeight());
//imperode.show();

for (var i = 1; i <= imperode.getStackSize(); i++){
  imporg1frame = ImagePlus("temporg", imporg.getStack().getProcessor(i).duplicate());
  impdummy = ImagePlus("temp", imperode.getStack().getProcessor(i).duplicate());
  impdummy.show();
  //IJ.setAutoThreshold(impdummy, "Default dark"); //or segmented cells 
  allroi = PrepareSeedV2(impdummy); //ShapeRoi retured
  //IJ.log(allroi.toString());
 // imporg.setRoi(allroi, true);
  if (allroi != null){
  imporg1frame.setRoi(allroi, true);
  impseg = doLevelSet(imporg1frame);
  binstk.addSlice(String(i), impseg.getProcessor());
  impseg.flush();
  }
  impdummy.close();
  imporg1frame.close();
}
binimp = ImagePlus("binarized", binstk);

//IJ.run(imp, "Invert", "stack");
//IJ.run(imp, "Watershed", "stack");
binimp.show();

IJ.saveAs(binimp, "Tiff", imgpath + savefilename);

//no RoiManager Version
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
 
function doLevelSet(imp){
//set parameters
  importClass(Packages.emblcmci.tools.LevelSetExt);
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

//deprecated
function PrepareSeed(locimp){
  var rt = ResultsTable();
  var rm = RoiManager();	//RoiManager will be hidden
  var paopt = ParticleAnalyzer.ADD_TO_MANAGER
    + ParticleAnalyzer.SHOW_MASKS 
    + ParticleAnalyzer.INCLUDE_HOLES
    + ParticleAnalyzer.EXCLUDE_EDGE_PARTICLES
    + ParticleAnalyzer.CLEAR_WORKSHEET; 
    + ParticleAnalyzer.SHOW_RESULTS; 
  //Double.POSITIVE_INFINITY
  var ptMinSize = 50;
  var ptMaxSize = 8500;
  var circMin = 0.1;
  var circMax = 1.0;
  var pa = new ParticleAnalyzer(paopt, 0, rt, ptMinSize, ptMaxSize, circMin, circMax);
  pa.setHideOutputImage(true); 
  pa.analyze(locimp); 
  var imp2 = pa.getOutputImage();
  //imp2.show();
  //var rm = RoiManager(true).getInstance();
  rm = RoiManager().getInstance();
  var rois = rm.getROIs();	//Hashtable
  var roisA = rm.getRoisAsArray() ;	//Array
  var en = rois.keys();

  IJ.log("roi number : " + roisA.length);
  var s1 = null;
  var s2 = null;
  while (en.hasMoreElements()){	
    var key = en.nextElement();
    var roi = rois.get(key);
    if (s1 == null){
      s1 = ShapeRoi(roi);
      IJ.log("s1 set");
    } else {
      s2 = ShapeRoi(roi);
      //IJ.log("s2 set");
      s1.or(s2);
    }
  }
  return s1;
}

//lsop = "method=[Active Contours] " 
  //+ "use_level_sets "
  //+ "grey_value_threshold=4 " 
  //+ "distance_threshold=1 "
  //+ "advection=2.20 "
  //+ "propagation=1 " 
  //+ "curvature=4 " 
  //+ "grayscale=30 "
  //+ "convergence=0.0050 " 
  //+ "region=outside";
//IJ.run(imporg, "Level Sets", isop);
/*
obj = IJ.runPlugIn(ImagePlus imp, java.lang.String className, java.lang.String arg); 
*/



//imp.updateAndDraw();

/*

	void combineRois(ImagePlus imp, int[] indexes) {
		ShapeRoi s1=null, s2=null;
		for (int i=0; i<indexes.length; i++) {
			Roi roi = (Roi)rois.get(list.getItem(indexes[i]));
			if (roi.isLine() || roi.getType()==Roi.POINT)
				continue;
			if (s1==null) {
				if (roi instanceof ShapeRoi)
					s1 = (ShapeRoi)roi;
				else
					s1 = new ShapeRoi(roi);
				if (s1==null) return;
			} else {
				if (roi instanceof ShapeRoi)
					s2 = (ShapeRoi)roi;
				else
					s2 = new ShapeRoi(roi);
				if (s2==null) continue;
				if (roi.isArea())
					s1.or(s2);
			}
		}
		if (s1!=null)
			imp.setRoi(s1);
	}
*/

//rm.runCommand("Combine");
