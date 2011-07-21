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
var mpimodel = new JavaImporter();
mpimodel.importPackage(Packages.mpicbg.models);
importPackage(Packages.java.util);
var mpistack = new JavaImporter();
mpistack.importPackage(Packages.mpicbg.ij.stack);
/*
var albertT = new JavaImporter();
albertT.importPackage(Packages.mpicbg.trakem2.transform);
mst = albertT.MovingLeastSquaresTransform();
*/
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
	//just to verify
	mat = new Array(12);
	fittedMA = modelM.getMatrix(mat);
	for (i in mat) IJ.log(mat[i].toString());
	for (i in fittedMA) IJ.log(fittedMA[i].toString());

/* test part
try {
	mst.setMatches( pointPairs );
} catch (err){
	IJ.log('An error has occurred: '+err.message); 
}
IJ.log(mst.toDataString());
*/

mapping = mpistack.InverseTransformMapping( modelM );

imp = IJ.getImage();
ww = imp.getWidth();
hh = imp.getHeight();
dd = imp.getImageStackSize();
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

function ReCalcStackSize(trasM, minA, maxA, imp){
  
}





