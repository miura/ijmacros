// LevelSetsEXT.js
// Kota Miura (miura@embl.de)
// 
// Works in Fiji, Requires extra jar file: LevelSetsExt.jar
// this file should be placed in the Fiji plugins folder.  

importClass(Packages.emblcmci.tools.LevelSetExt);
imp = IJ.getImage();

//set parameters
useFastMarching = false;
useLevelSets = true;
greyValueThreshold = 4.0;  
distanceThreshold = 1.0;
advection = 2.20;
curvature = 1; 
propagation = 1;
grayscale = 30;
convergence = 0.0050;
inwards = false;
// parameter setting finished

//constructor of LevelSets with parameters
ls = new LevelSetExt(useFastMarching, useLevelSets, 
	distanceThreshold, greyValueThreshold, 
	advection, curvature, propagation, grayscale, convergence, 
	inwards);
//execution with current image imp
impout = ls.execute(imp, false); //arg[1] = false suppresses the display of progress image window
impout.show();
