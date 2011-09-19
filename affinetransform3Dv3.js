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
var jio    = new JavaImporter();
mpimodel.importPackage(Packages.mpicbg.models);
trakmodel.importPackage(Packages.mpicbg.trakem2.transform);
mpistack.importPackage(Packages.mpicbg.ij.stack);
jarray.importPackage(Packages.java.lang.reflect);
jio.importPackage(Packages.java.io);
importClass(Packages.ij.util.Tools);
importPackage(Packages.util.opencsv);

/*
   var albertT = new JavaImporter();
   albertT.importPackage(Packages.mpicbg.trakem2.transform);
   mst = albertT.MovingLeastSquaresTransform();
   */
var args = getArgument();
var argA = Tools.split(args, ":");
var imgfilepath = argA[0];
var datafilepath = argA[1];

pointPairs = new ArrayList();
//testFillPoints(pointPairs);
FillPointsfromFile(pointPairs, datafilepath);

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

//imp = IJ.getImage();	// move this later to the beginning to check if there is indeed an image stack opened
imp = IJ.openImage(imgfilepath);
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

for (var i in minA) IJ.log(minA[i]);
for (var i in maxA) IJ.log(maxA[i]);

outstr = "after: ";
for (var i in minA) outstr = outstr + destsizeA[i] + ",";
IJ.log(outstr);

ReCalcOffset(modelM, minA);
IJ.log(modelM.toDataString());

// --- stack transformation ---

mapping = mpistack.InverseTransformMapping( modelM );

ip =  imp.getStack().getProcessor( 1 ).createProcessor( 1, 1 ); 
target = new ImageStack(ww, hh);
for ( var s = 0; s < dd; ++s ) { 
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

// -- for saving output file
fo = jio.File(imgfilepath);
fname = fo.getName().slice(0, -4);
pname =  fo.getParent();
IJ.log(fname)
IJ.log(dname)
newfilepath = dname + File.separator+ fname + "Out.tif";
IJ.saveAs(impout, "Tiff", newfilepath); 
IJ.log("Saved first frame as: " + newfilepath);

//GUI
impout.show();


function testFillPoints(pointPairs) {
  var p11 = [1, 0, 0];
  var p12 = [0, 1, 0];

  var p21 = [0, 1, 0];
  var p22 = [0, 0, 1];

  var p31 = [0, 0, 1];
  var p32 = [1, 0, 0];

  var p41 = [0.5, 0, 0];
  var p42 = [0, 0.5, 0];

  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p11), mpimodel.Point(p12)));
  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p21), mpimodel.Point(p22)));
  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p31), mpimodel.Point(p32)));
  pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p41), mpimodel.Point(p42)));
  IJ.log(pointPairs.toString());
}

function FillPointsfromFile(pointPairs, datafilepath){
	var dataA = new ArrayList();
	//filepath = java.lang.String(dir + sp + filesA[i]);
	if (datafilepath.endsWith(".txt") || datafilepath.endsWith(".csv")) {
		IJ.log(datafilepath);
		readCSV(datafilepath, dataA);
	} else {
		IJ.log("problem reading: " + datafilepath);
	}

	var datait = dataA.iterator();
	while (datait.hasNext()){
		//IJ.log(datait.next()[0]);
		var carray = datait.next();
		var p1 = [carray[0], carray[1], carray[2]];
		var p2 = [carray[3], carray[4], carray[5]];
		pointPairs.add(mpimodel.PointMatch(mpimodel.Point(p1), mpimodel.Point(p2)));
	}
	IJ.log("=== point pairs loaded from " + datafilepath);	
	IJ.log(pointPairs.toString());	  
}

function ReCalcStackSize(transM, minA, maxA){
  transM.estimateBounds(minA, maxA);
  var newsizeA = [0.0, 0.0, 0.0];  
  for (var i in newsizeA) 
    newsizeA[i] = Math.ceil(maxA[i] - minA[i]);
  return newsizeA;
}

function ReCalcOffset(transM, minA){
  var shift = new mpimodel.TranslationModel3D();
  shift.set( -1*minA[0], -1*minA[1], -1*minA[2] );
  transM.preConcatenate(shift);
}

function readCSV(filepath, dataA) {
    var reader = new CSVReader(new FileReader(filepath), ",");
    var ls = reader.readAll();
    var it = ls.iterator(); 
    while (it.hasNext()){
        var carray = it.next();
        dataA.add(carray);
        //IJ.log(carray[4]); 
    }
}




