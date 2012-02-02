// test for Mesh_Maker,createTube

importClass(Packages.java.util.Vector);
importPackage(Packages.ij3d);
importClass(Packages.customnode.CustomTriangleMesh);
importClass(Packages.javax.vecmath.Color3f);

col = Color3f(0, 1.0, 0.5);
col2 = Color3f(1.0, 0, 0);
colw = Color3f(1.0, 1.0, 1.0);

var xA = javaArray(1, 10);
var yA = javaArray(1, 10);
var zA = javaArray(1, 10);
var rA = javaArray(1, 1);
var tube = Mesh_Maker.createTube(xA, yA, zA, rA, 20, false);
var xA = javaArray(10, 20);
var yA = javaArray(10, 20);
var zA = javaArray(10, 10);
var rA = javaArray(1, 1);
var tube2 = Mesh_Maker.createTube(xA, yA, zA, rA, 20, false);
var tubes = Vector();		
tubes.addAll(tube);
tubes.addAll(tube2);
var csp = CustomTriangleMesh(tubes, colw, 0.0);
var ccs = ContentCreator.createContent(csp, "tubetime test", 0);
univ = new Image3DUniverse();
univ.show();
univ.addContent(ccs);
			
function javaArray(sp, ep){
	ja = new java.lang.reflect.Array.newInstance(java.lang.Double.TYPE, 2);
	ja[0] = sp;
	ja[1] = ep;
	return ja;
}


