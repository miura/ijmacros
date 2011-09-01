// LevelSetsEXT.js
// Kota Miura (miura@embl.de)
// 
// Works in Fiji, Requires extra jar file: LevelSetsExt.jar
// this file should be placed in the Fiji plugins folder.  

importClass(Packages.emblcmci.tools.LevelSetExt);
imp1 = IJ.getImage();
imp2 = doLevelSet(imp1)
imp2.show();
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
	impout = ls.execute(imp, true); //arg[1] = false suppresses the display of progress image window
	return impout;
}

