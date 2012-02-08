importClass(Packages.ij3d.Image3DUniverse);
importClass(Packages.javax.vecmath.Color3f);
//importClass(Packages.ij3d.Mesh_Maker);
importClass(Packages.customnode.CustomTriangleMesh);
importClass(Packages.customnode.CustomMultiMesh);
importClass(Packages.ij3d.Mesh_Maker);

univ = new Image3DUniverse();
univ.show();

col = Color3f(0, 1.0, 0.5);
col2 = Color3f(1.0, 0, 0);
colw = Color3f(1.0, 1.0, 1.0);

function putSphere(univ, x, y, z, r, merid, para, color, name){
	msp = Mesh_Maker.createSphere(x, y, z, r, merid, para);
	univ.addTriangleMesh(msp, color, name);
}

putSphere(univ, 0.0, 0.0, 30.0, 50.0, 24.0, 24.0, colw, "testsphere");
putSphere(univ, 100.0, 100.0, 30.0, 25.0, 24.0, 24.0, col, "testsphere1");

/* multi methods
sp = Mesh_Maker.createSphere(0.0, 0.0, 30.0, 50.0, 24.0, 24.0);
sp2 = Mesh_Maker.createSphere(100.0, 100.0, 30.0, 25.0, 24.0, 24.0);
sp.addAll(sp2);
csp = CustomTriangleMesh(sp, col, 0.0);
ctri = univ.addCustomMesh(csp, "spheres");



for (var i = timestart; i < timeend; i++){
	var spheres = Vector();
	for (var j = 0; j < tList.size(); j++) {
		var curtraj = tList.get(j);
		if (CheckTimePointExists(i, curtraj.timepoints)){
			IJ.log(curtraj.id);
			var ind = timeextract.indexOf(i);
			var p3f = curtraj.dotList.get(ind);
			var curtime = curtraj.timepoints.get(ind);
			var sphere = Mesh_Maker.createSphere(p3f.x, p3f.y, p3f.z, 5.0, 24.0, 24.0);
			spheres.addAll(sphere);
		}
	}
	csp = CustomTriangleMesh(spheres, col, 0.0);
	cc = ContentCreator.createContent(csp, "time" + Integer.toString(i), i-timestart);
	univ.addContent(cc);
}


*/