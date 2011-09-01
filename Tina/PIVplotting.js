// for Lotting VectorField using PIV output plugin
// Kota Miura (miura@embl.de)
// 
// Collaborator: Tina @ De Renzis
//
// some pathes alternatively used
//path = "D:\\People\\Tina\\20110813\\out\\";
//path = "Z:\\Tina\\outNoneSeg\\";
//filename ="PIV_segmented_f88_90.txt"; 
//filename ="PIV_segmented_f01_02.txt";
//filename ="segmented.tif48_49.txt";

importPackage(java.io);
path = "Z:\\Tina\\outNoneSeg";
//path = "D:\\People\\Tina\\20110813\\out";
//path = "Z:\\Tina\\test";
dir = new File(path);
filesA = dir.list();
sp = File.separator;

filesA.sort(comparator);
importClass(Packages.ij.macro.Interpreter);
macro = new Interpreter(); 
macro.batchMode = true;
for (var i=0; i<filesA.length; i++) {
	filepath = java.lang.String(dir + sp + filesA[i]);
	if (filepath.endsWith(".txt")) {
        	IJ.log(filepath);
        	//readCSV(filepath);
        	try {
	        	PIVplotter(path, filesA[i], sp);
	        	imp = IJ.getImage(); //vecfield
	        	if (i == 0)
	        		stkout = ImageStack(imp.getWidth(), imp.getHeight());
       			stkout.addSlice(filesA[i], imp.getProcessor().duplicate());
        		imp.close();
        	} catch (err){
			macro.batchMode = false;
			IJ.log("!Error with do process...");
			IJ.log(err.rhinoException.toString());
			IJ.log(err.javaException.toString());         		
        	}
	} else {
        	IJ.log("Igonored: " + filepath);
	}
}
macro.batchMode = false;
impout = ImagePlus("vecField", stkout);
impout.show();


// Sorting function
function comparator(stra, strb){
	var patt1 = /\.tif([0-9]{1,10})_/i;
	regexa = stra.match(patt1);
	regexb = strb.match(patt1);	
	return (regexa[1] - regexb[1]) 
}

function PIVplotter(path, filename, sp){
	var arg1 = "select=" + path + sp + filename; 
	var op = arg1 	
//		+" vector_scale=15 max=3 plot_width=512 plot_height=512 show lut=S_Pet";
		+" vector_scale=15 max=1.5 plot_width=512 plot_height=512 lut=S_Pet";		
	IJ.log(op);
	IJ.run("plot...", op);
}