// test for adjusting destination stack size

var mpimodel = new JavaImporter();
mpimodel.importPackage(Packages.mpicbg.models);
var trakmodel = new JavaImporter();
trakmodel.importPackage(Packages.mpicbg.trakem2.transform);

importPackage(Packages.java.util);
var mpistack = new JavaImporter();
mpistack.importPackage(Packages.mpicbg.ij.stack);
var jarray = new JavaImporter();
jarray.importPackage(Packages.java.lang.reflect);

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
modelM = new trakmodel.AffineModel3D();
modelM.fit( pointPairs );
IJ.log(modelM.toDataString());

imp = IJ.getImage();
ww = imp.getWidth();
hh = imp.getHeight();
dd = imp.getImageStackSize();

// need to use java native array for estimateBounds() method.
minA = jarray.Array.newInstance(java.lang.Float.TYPE, 3);
maxA = jarray.Array.newInstance(java.lang.Float.TYPE, 3);

minA[0] = 0.0;
minA[1] = 0.0;
minA[2] = 0.0;
maxA[0] = ww;
maxA[1] = hh;
maxA[2] = dd;

destsizeA = ReCalcStackSize(modelM, minA, maxA);

IJ.log("original:"+ ww.toString() +"," + hh.toString()+ "," + dd.toString()); 
for (i in minA)IJ.log(minA[i]);
for (i in maxA)IJ.log(maxA[i]);
outstr = "after: ";
for (var i = 0; i < minA.length; i++)
  outstr = outstr + destsizeA[i] + ",";
IJ.log(outstr);

ReCalcOffset(modelM, minA);
IJ.log(modelM.toDataString());

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

