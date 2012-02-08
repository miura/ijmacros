
importClass(Packages.java.util.Vector);
importPackage(Packages.util.opencsv);
importPackage(java.io);

originalpath = '/Volumes/cmci/mette/data20111213cut500.csv';
pList = loadPointsFile(originalpath);
for(var i =0; i<1000; i++)
	IJ.log(pList.get(i).frame);

function loadPointsFile(datapath){

	var reader = new CSVReader(new FileReader(datapath), ",");
	var ls = reader.readAll();
	var it = ls.iterator();
	var counter = 0;
	var currentTrajID = 1.0;
	var coords = Vector();
	while (it.hasNext()){
		var cA = it.next();
		if (counter != 0){
			var pf = Double.valueOf(cA[2]);
			var pmeanint = Double.valueOf(cA[7]);
			var px = Double.valueOf(cA[10]);
			var py = Double.valueOf(cA[11]);
			var pz = Double.valueOf(cA[12]);
			var sx = Double.valueOf(cA[13]);
			var sy = Double.valueOf(cA[14]);
			var sz = Double.valueOf(cA[15]);											
			var dotObj = new DotObj(pf, px, py, pz, sx, sy, sz, pmeanint);
			coords.add(dotObj);
		}
		counter++;
	}
	return coords;
}

//pointObject
function DotObj(frame, x, y, z,sx, sy, sz, meanint) {
	this.frame = frame;
	this.x = x;
	this.y = y;
	this.z = z;
	this.sx = sx;
	this.sy = sy;
	this.sz = sz;	
	this.meanint = meanint; 
}