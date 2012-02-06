// Olivier's Measurement tool, muscle fiber. miura@embl.de 20110414
// 110415 suppressed NaN error due to 'infinity' slope.
// 110511-3 added Gaussian fitting for the averaged curve. 
// TODO: fit each profile, rather than fitting the averaged.
importPackage(Packages.ij.measure.Curvefitter)
roiwidth = 10	//half of the length of tangential ROIto be measured. 

imp = IJ.getImage();
coordA = segROICoords(imp);
//slA = returnSlope(coordA);
slA = returnSlopeV2(coordA);
for (var i in slA) slA[i] = -1/slA[i];
/*
for (var i in coordA[0]) {
	IJ.log(coordA[0][i] + ", " + coordA[1][i] + ": slope "+ slA[i]);
	if (slA[i] == Number.NEGATIVE_INFINITY) IJ.log("-inf");
}
*/

oldrm = RoiManager().getInstance();
if (oldrm != null) oldrm.close();

rm = new RoiManager();
var aveprofile = [];
var diameterA = [];
var goodnessA = [];
for (var i in coordA[0]){
	//IJ.log(coordA[0][i] +","+ coordA[1][i] +","+ slA[i]);
	SetTangentialRoi(imp, coordA[0][i], coordA[1][i], slA[i]);
	rm.addRoi(imp.getRoi());
	var prof = new ProfilePlot(imp);
	var curprofile = prof.getProfile();
	var resA = GaussFitReturnPara(curprofile, false);
  // here, just pass the parameter back and add diameter and goodness
	diameterA[i] = resA[resA.length-1];
	goodnessA[i] = resA[resA.length-2];
		
	if (i == 0) for (var i in curprofile) aveprofile[i] = 0.0;
	for (var j in curprofile) aveprofile[j] += curprofile[j]; 	
}
for (var i in aveprofile) aveprofile[i] = aveprofile[i] / coordA[0].length;

//var profx = [];
var profx = java.lang.reflect.Array.newInstance(java.lang.Double.TYPE, aveprofile.length);
for (var i = 0.0; i < aveprofile.length; i+=1.0) profx[i] = i;

for (var i in aveprofile) IJ.log(aveprofile[i]);
pl = new Plot("CrossSectionProfile", "distance", "average intensity", profx, aveprofile);
pl.show();

GaussFit(aveprofile, true);
	
function SetTangentialRoi(imp, xx, yy, slope){
	var aq = Math.pow(slope, 2) + 1;
	var bq = -2 * xx * (1 + Math.pow(slope, 2));
	var cq = (1 + Math.pow(slope, 2)) * Math.pow(xx, 2) - Math.pow(roiwidth, 2);

	var xa =0; ya = 0; xb = 0; yb = 0;
	
	//IJ.log(aq +","+ bq +","+ cq);
	if ((slope != Number.NEGATIVE_INFINITY) && (slope != Number.POSITIVE_INFINITY)){	
		xa = quadratic(aq, bq, cq, "+")
		xb = quadratic(aq, bq, cq, "-")
		ya = slope * xa - slope * xx + yy;
		yb = slope * xb - slope * xx + yy;
	} else {
		xa = xx;
		ya = yy + roiwidth;
		xb = xx
		yb = yy - roiwidth;		
	}
	IJ.log("["+xx +","+ yy +"]:"+ slope);
	IJ.log("  point1: " + xa + ", " + ya);
	IJ.log("  point2: " + xb + ", " + yb);
/*
xpt = [xa, xb];
ypt = [ya, yb];
imp.setRoi(new PolygonRoi(xpt, ypt, 2, ROI.POLYLINE));
*/
	imp.setRoi(new Line(xa, ya, xb, yb));
}


/*
xpoints = [22,54,55,78,82];
ypoints = [23,34,61,75,86];
imp.setRoi(new PolygonRoi(xpoints,ypoints,5,Roi.POLYLINE));
*/
// converts segemented ROI to coordinates and returns multidimensional array
// with xy coordinates stored.  
function segROICoords(imp){
	IJ.run(imp, "Fit Spline", "");
	var roi = imp.getRoi();
	var br = roi.getBounds(); 
	var xa = roi.getXCoordinates();
	var ya = roi.getYCoordinates();

	for (var i in xa) {
		xa[i] += br.x;
		ya[i] += br.y;
	}
	var combA=[xa, ya];
	return combA;
}

//calculates slope at each time point and returns slope.
//DEPRICATED, use returnSlopeV2V2 
function returnSlope(inarray){
	var slopeA = [];
	var tempS = (inarray[1][2] - inarray[1][0]) /(inarray[0][2] - inarray[0][0]);
	var arlen = inarray[0].length;
	slopeA.push((inarray[1][0] - inarray[1][2]) /(inarray[0][0] - inarray[0][2])); 	
	for(var i = 1; i < (arlen - 1); i++ )
		slopeA.push((inarray[1][i-1] - inarray[1][i+1]) /(inarray[0][i-1] - inarray[0][i+1]));
	slopeA.push((inarray[1][arlen - 1] - inarray[1][arlen - 3]) /(inarray[0][arlen - 1] - inarray[0][arlen - 3])); 	
	return slopeA;
}

//slope estimation by stragiht fit
function returnSlopeV2(inarray){
	var slopeA = [];
	var txa = [];
	var tya = [];
	var arlen = inarray[0].length;
	var seglength = 5 // number of points to take for the fitting. 	
	var offset = Math.floor(seglength/2);
	if (seglength > arlen) return null;
	var stp = 0;
	var enp = 0;
	for(var i = 0; i < arlen; i++ ){
		stp = i - offset;
		enp = i + offset;
		if (stp < 0) {
			enp = enp + offset;
			stp = 0;
		}
		if (enp > (arlen-1)) {
			stp = (stp - offset);
			enp = arlen - 1;
		}
		for (var j = 0; j < seglength; j++){
			txa[j] = inarray[0][stp + j];
			tya[j] = inarray[1][stp + j];
		}
		cf = CurveFitter(txa, tya);
		cf.doFit(0);
		slopeA[i] = cf.getParams()[1];			
	}
	return slopeA;
}


//Solving quadratic formula
/**
 * Rounds number to "dp" decimal places.
 *
 * @author Gary Jones
 * @link http://code.garyjones.co.uk/category/javascript/
 */
function chop(number, decimal_places)
{
	var multiplier = Math.pow(10, decimal_places) // makes multiplier = 10^decimal_places.
	number = ( Math.round( number * multiplier ) ) / multiplier;
/*	if ( document.layers ){ // Tidies Netscape 4.x appearance.
		if ( number < 1 && number >= 0 ) number = "0" + number; // makes .752 to 0.752
		if ( number < 0 && number >-1 ) number = "-0" + number * -1 // makes -.367 to -0.367
	}
*/	return number;
}

/**
 * Finds two roots.
 *
 * For ax^2 + bx + c = 0, use quadratic("a", "b", "c", "+") and quadratic("a", "b", "c", "-").
 */
function quadratic(aq, bq, cq, root)
{
	var complex,
		lambda,
		lambdaone,
		lambdatwo,
		plusminusone,
		plusminustwo,
		bsmfac = bq * bq - 4 * aq * cq,
		precision = 3;
	if ( bsmfac < 0 ) { // Accounts for complex roots.
		plusminusone = " + ";
		plusminustwo = " - ";
		bsmfac *= -1;
		complex = Math.sqrt( bsmfac ) / ( 2 * aq );
		if ( aq < 0 ){ // if negative imaginary term, tidies appearance.
			plusminusone = " - ";
			plusminustwo = " + ";
			complex *= -1;
		}
		lambdaone = chop( -bq / ( 2 * aq ), precision ) + plusminusone + chop( complex, precision ) + 'i';
		lambdatwo = chop( -bq / ( 2 * aq ), precision ) + plusminustwo + chop( complex, precision ) + 'i';
	} else if ( 0 == bsmfac ){ // Simplifies if b^2 = 4ac (real roots).
		lambdaone = chop( -bq / ( 2 * aq ), precision );
		lambdatwo = chop( -bq / ( 2 * aq ), precision );
	} else { // Finds real roots when b^2 != 4ac.
		lambdaone = (-bq + (Math.sqrt( bsmfac ))) / ( 2 * aq );
		lambdaone = chop( lambdaone, precision );
		lambdatwo = (-bq - (Math.sqrt( bsmfac ))) / ( 2 * aq );
		lambdatwo = chop( lambdatwo, precision );
	}
	( '+' == root ) ? lambda = lambdaone : lambda = lambdatwo;
	return lambda; // Returns either root based on parameter "root" passed to function.
}

// does gaussian fitting and return 2sigma value, presumably the radius. 
// getting the half-max width: refer to 
// 	http://hyperphysics.phy-astr.gsu.edu/hbase/math/gaufcn2.html

function GaussFit(profileA, doPlot){
  //var pixx = [];
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

//returns diameter and goodness of fit
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
  resultsA = cfp;
  resultsA[resultsA.length] = diameter;
  resultsA[resultsA.length] = cf.getFitGoodness();
  return resultsA;  
}

