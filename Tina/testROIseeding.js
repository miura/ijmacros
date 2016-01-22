impdummy = IJ.getImage();
allroi = PrepareSeedV2(impdummy); //ShapeRoi retured
  //IJ.setAutoThreshold(impdummy, "Default dark"); //or segmented cells
impdummy.setRoi(allroi, true);
IJ.log("done");

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