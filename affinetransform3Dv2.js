//  affinetransform3D.js
//  Created: 201107120 by Kota Miura (CMCI, EMBL miura@embl.de)
//
// 	Collaborater: Oleg
//
// written according to the advice from Stephan Saalfeld@mpicbg
// http://groups.google.com/group/fiji-users/browse_thread/thread/4e70cd4caf96d180
// TODO try using moving least square. 
// http://pacific.mpi-cbg.de/javadoc/mpicbg/models/MovingLeastSquaresTransform.html
// http://www.ini.uzh.ch/~acardona/api/mpicbg/trakem2/transform/MovingLeastSquaresTransform.html
importPackage(Packages.java.util);
var mpimodel  = new JavaImporter();
var trakmodel = new JavaImporter();
var mpistack  = new JavaImporter();
var jarray    = new JavaImporter();
mpimodel.importPackage(Packages.mpicbg.models);
trakmodel.importPackage(Packages.mpicbg.trakem2.transform);
mpistack.importPackage(Packages.mpicbg.ij.stack);
jarray.importPackage(Packages.java.lang.reflect);


/*
   var albertT = new JavaImporter();
   albertT.importPackage(Packages.mpicbg.trakem2.transform);
   mst = albertT.MovingLeastSquaresTransform();
   */
pointPairs = new ArrayList();
testFillPoints(pointPairs);

//LS fitting
modelM = new trakmodel.AffineModel3D();	//use Albert's class, for printing out matrix
modelM.fit( pointPairs );
IJ.log(modelM.toDataString());

/* test part
   try {
   mst.setMatches( pointPairs );
   } catch (err){
   IJ.log('An error has occurred: '+err.message); 
   }
   IJ.log(mst.toDataString());
   */

// --- preparing target stack size, offsets ---

imp = IJ.getImage();	// move this later to the beginning to check if there is indeed an image stack opened
ww  = imp.getWidth();
hh  = imp.getHeight();
dd  = imp.getImageStackSize();

// need to use java native array for estimateBounds() method.
minA = jarray.Array.newInstance(java.lang.Float.TYPE, 3);
maxA = jarray.Array.newInstance(java.lang.Float.TYPE, 3);

minA[0] = 0.0;
minA[1] = 0.0;
minA[2] = 0.0;
maxA[0] = ww;
maxA[1] = hh;
maxA[2] = dd;

IJ.log("original:"+ ww.toString() +"," + hh.toString()+ "," + dd.toString()); 

destsizeA = ReCalcStackSize(modelM, minA, maxA);

ww = destsizeA[0];
hh = destsizeA[1];
dd = destsizeA[2];

for (i in minA) IJ.log(minA[i]);
for (i in maxA) IJ.log(maxA[i]);

outstr = "after: ";
for (i in minA) outstr = outstr + destsizeA[i] + ",";
IJ.log(outstr);

ReCalcOffset(modelM, minA);
IJ.log(modelM.toDataString());

// --- stack transformation ---

mapping = mpistack.InverseTransformMapping( modelM );

ip =  imp.getStack().getProcessor( 1 ).createProcessor( 1, 1 ); 
target = new ImageStack(ww, hh);
for ( s = 0; s < dd; ++s ) { 
  ip = ip.createProcessor( ww, hh ); 
  mapping.setSlice( s ); 
  try { 
    mapping.mapInterpolated( imp.getStack(), ip ); 
  } catch ( err ) { 
    alert('An error has occurred: '+err.message); 
  } 
  target.addSlice( "", ip ); 
}
impout = ImagePlus("out", target);
impout.show();


function testFillPoints(pointPairs) {
  p11 = [1, 0, 0];
  p12 = [0, 1, 0];

  p21 = [0, 1, 0];
  p22 = [0, 0, 1];

  p31 = [0, 0, 1];
  p32 = [1, 0, 0];

  p41 = [0.5, 0, 0];
  p42 = [0, 0.5, 0];

  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p11), mpimodel.Point(p12)));
  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p21), mpimodel.Point(p22)));
  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p31), mpimodel.Point(p32)));
  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p41), mpimodel.Point(p42)));
  IJ.log(pointPairs.toString());
}

function ReCalcStackSize(transM, minA, maxA){
  transM.estimateBounds(minA, maxA);
  newsizeA = [0.0, 0.0, 0.0];  
  for (i in newsizeA) 
    newsizeA[i] = Math.ceil(maxA[i] - minA[i]);
  return newsizeA;
}

function ReCalcOffset(transM, minA){
  shift = new mpimodel.TranslationModel3D();
  shift.set( -1*minA[0], -1*minA[1], -1*minA[2] );
  transM.preConcatenate(shift);
}





