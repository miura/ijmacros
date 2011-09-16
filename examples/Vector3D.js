importClass(Packages.org.apache.commons.math.geometry.euclidean.threed.Vector3D);

//construct 2 vectors
va = new Vector3D(0.0, 0.0, 2.0);
vb = new Vector3D(2.0, 0.0, 0.0);

//angle between va and vb 
ang = Vector3D.angle(va, vb);
IJ.log(ang);

//add va and vb, and out puts a new vector as a result
vc = new Vector3D(1.0, va, 1.0, vb);

//prints out elements of the vector vc
IJ.log("" + vc.getX()+ "," + vc.getY()+ "," + vc.getZ());

//dot (inner) product of va abd vb
dp = va.dotProduct(vb);
IJ.log(dp);

//cross product of va abd vb
vd = va.crossProduct(vb);
IJ.log("" + vd.getX()+ "," + vd.getY()+ "," + vd.getZ());