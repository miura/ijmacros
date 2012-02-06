//Only the Gaussian V2 
//
importPackage(Packages.ij.measure.Curvefitter);
//importClass(Packages.java.lang.reflect.Array);
imp = IJ.getImage();
prof = ProfilePlot(imp);
curprofile = prof.getProfile();
IJ.log(curprofile.length);
rA = GaussFitReturnPara(curprofile, false);
IJ.log(rA[1]);

//doPlot: boolean
function GaussFitReturnPara(profileA, doPlot){
  //var pixx = [];
  var resultsA = [];
  var pixx = java.lang.reflect.Array.newInstance(java.lang.Double.TYPE, profileA.length);
  for (var i=0; i<profileA.length ; i++) pixx[i] = Number(i); 
  cf = new CurveFitter(pixx, profileA);
  cf.doFit(cf.GAUSSIAN);
  IJ.log(cf.getResultString()); //debugging
  cfp = cf.getParams();
  //diameter = 2.355*cfp[3]; half max
  diameter = 4*cfp[3];	// 2*sigma 
  EstimatedDiameter = "Diameter =" + diameter;
  IJ.log("Goodness of Fit (1.0 is the best): " + cf.getFitGoodness());
  IJ.log("Estiamted Diameter = " + diameter);
  if (doPlot) PlotFitted(pixx, profileA, cf, cfp, EstimatedDiameter);
  resultsA[0] = diameter;
  resultsA[1] = cf.getFitGoodness();
  return resultsA;  
}
