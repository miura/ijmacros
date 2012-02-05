//Only the Gaussian 
//
importPackage(Packages.ij.measure.Curvefitter);
importClass(Packages.java.util.HashMap);

headerA = ["Iterations", "Restarts", "SumResidualSquared", "SD", "R^2", "FitGoodness","Diameter"];

//importClass(Packages.java.lang.reflect.Array);
imp = IJ.getImage();
prof = ProfilePlot(imp);
curprofile = prof.getProfile();
IJ.log(curprofile.length);
resultsA = GaussFit(curprofile, true);
//for(var i = 0; i< resultsA.size(); i++) IJ.log(resultsA.get(headerA[i]));
//for (var i in resultsA) IJ.log(resultsA.get(headerA[i]));
var iter = resultsA.entrySet().iterator();
while (iter.hasNext())
	//IJ.log(iter.next().getValue());
	IJ.log(iter.next());
writetoResultstable(resultsA, headerA, false);

//doPlot: boolean
function GaussFit(profileA, doPlot){
  //var pixx = [];
  var pixx = java.lang.reflect.Array.newInstance(java.lang.Double.TYPE, profileA.length);
  for (var i=0; i<profileA.length ; i++) pixx[i] = Number(i); 
  cf = new CurveFitter(pixx, profileA);
  cf.doFit(cf.GAUSSIAN);
  IJ.log(cf.getResultString()); //debugging
  cfp = cf.getParams();
  diameter = 2.355*cfp[3];
  EstimatedDiameter = "Diameter =" + diameter;
  IJ.log("Estiamted Diameter = " + diameter);
  if (doPlot) PlotFitted(pixx, profileA, cf, cfp, EstimatedDiameter);
  var resA = HashMap();
  resA.put(headerA[0], cf.getIterations());
  resA.put(headerA[1], cf.getRestarts());
  resA.put(headerA[2], sqsum(cf.getResiduals()));
  resA.put(headerA[3], cf.getSD());
  resA.put(headerA[4], cf.getRSquared());
  resA.put(headerA[5], cf.getFitGoodness());
  resA.put(headerA[6], diameter);
  return resA;  
} 

// cf: class CurveFitter
// cfp: fitted parameter array
// estD: estimated diameter
function PlotFitted(xA, yA, cf, cfp, estD){
 var fitA = [];
 for (i in yA)
  fitA[i] = cf.f(cfp, i);
 fitplot = Plot("fitted", "pixels", "intensity", xA, fitA)
 fitplot.addPoints(xA, yA, fitplot.CIRCLE)
 fitplot.addLabel(0.1, 0.1, estD)
 fitplot.show()
}

//+ Carlos R. L. Rodrigues
//@ http://jsfromhell.com/array/sum [rev. #1]

function sqsum(o){
	s = 0;
	for(var i = 0; i < o.length; i++) s += Math.pow(o[i], 2);
	return s;
}
function writetoResultstable(resMap, hA, clearTable){
	var rt = ResultsTable.getResultsTable();
	if (clearTable) rt.reset();
	var row = rt.getCounter();
	rt.incrementCounter();

	var iter = resultsA.entrySet().iterator();
  for (var i = 0; i < hA.length; i++) 
    rt.setValue(hA[i], row, resultsA.get(hA[i]));
	//while (iter.hasNext()){
	//	element = iter.next();
	//	rt.setValue(element.getKey(), row, element.getValue());
	//IJ.log(iter.next().getValue());
	//IJ.log(iter.next());
	//for (var i = 0; i < slices; i++){
		/*
		gl.setglcm(glcmA[i]);
		if (i == (slices-1)) gl.writetoResultsTable(true);
		else gl.writetoResultsTable(false);
		*/
		//status = "" + i + "/"+  slices;
		//IJ.showStatus("GLCM calculated: writing results:" + status);		
		//IJ.showProgress((i+1)/slices);
	
	rt.show("Results");

}

//map is an instance of javamap, retrieved from the java instance
// rt is the current results table. 
//paranamesA is the arary containing parameter names
function WritetoResults(map, rt, paranamesA){
	var javamap = HashMap(map);
	//IJ.log(javamap.get("Energy"));
	var row = rt.getCounter();
	rt.incrementCounter();
	for (var k = 0; k < paranamesA.length; k++)
		rt.setValue(paranamesA[k], row, javamap.get(paranamesA[k]));	
}
