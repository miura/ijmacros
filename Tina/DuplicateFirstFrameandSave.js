importClass(Packages.ij.util.Tools);
importClass(Packages.java.io.File);

args = getArgument();
argA = Tools.split(args, ":");
filepath = argA[0];
IJ.log("source stack: " + filepath);

imp = IJ.openImage(filepath, 1);
fo = File(filepath);
filename = fo.getName().slice(0, -4);
dirname =  fo.getParent();
IJ.log(filename)
IJ.log(dirname)
newfilepath = dirname + File.separator+ filename + "f1.tif";
IJ.saveAs(imp, "Tiff", newfilepath); 
IJ.log("Saved first frame as: " + newfilepath);

//old version
//--- split file path argument, extract the file name ---
/*
fpA = Tools.split(argA[0], "/");
path = "/";
for (i in fpA){
	if (i != (fpA.length - 1))
		path = path + fpA[i] + "/";
	else
		file = fpA[i];
}
*/
//filename = file.slice(0, -4);


