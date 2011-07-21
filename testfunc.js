var mpimodel = new JavaImporter();
mpimodel.importPackage(Packages.mpicbg.models);
importPackage(Packages.java.util);
var mpistack = new JavaImporter();
mpistack.importPackage(Packages.mpicbg.ij.stack);

pointPairs = new ArrayList();
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

//LS fitting
modelM = new mpimodel.AffineModel3D();
modelM.fit( pointPairs );

imp = IJ.getImage();
ww = imp.getWidth();
hh = imp.getHeight();
dd = imp.getImageStackSize();
//pixels = new java.lang.reflect.Array.newInstance(java.lang.Byte.TYPE, width * height);
minA = [0, 0, 0];
maxA = [ww, hh, dd]; 
destsizeA = ReCalcStackSize(modelM, minA, maxA);
//modelM.estimateBounds(minA, maxA);
//newsizeA = [0.0, 0.0, 0.0]; 
/*
IJ.log("original:"+ ww.toString() +"," + hh.toString()+ "," + dd.toString()); 
for (i in minA)
  IJ.log(minA[i]);
for (i in maxA)
  IJ.log(maxA[i]);
for (i in destsizeA) 
  destsizeA[i] = maxA[i] - minA[i];  
*/
//newsizeA[i] = Math.ceil(maxA[i] - minA[i]);  
for (var i = 0; i < minA.length; i++)
  IJ.log(destsizeA[i]);


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

