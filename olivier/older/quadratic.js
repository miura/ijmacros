//this is a text program to calculate 


//current point
xx = 2;
yy = 2;
//
roiwidth = 2*1.414	//half of the length of tangential ROIto be measured. 
slope = 0 // slope of the tangential vector: this should be calculated from ROI

ac = Math.pow(slope, 2) + 1;
bc = -2 * xx * (1 + Math.pow(slope, 2));
cc = (1 + Math.pow(slope, 2)) * Math.pow(xx, 2) - Math.pow(roiwidth, 2);

aq = ac;
bq = bc;
cq = cc;

xa = quadratic(aq, bq, cq, "+")
xb = quadratic(aq, bq, cq, "-")
ya = slope * xa - slope * xx + yy;
yb = slope * xb - slope * xx + yy;
IJ.log("point1: " + xa + ", " + ya);
IJ.log("point2: " + xb + ", " + yb);

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