// Example code for managing path strings. 
// Kota Miura (miura@embl.de)
// ... assumes Unix style path
// ... assumes that the script is executed from command line. 
// ... argment should be in the form <a path>:<another path>

args = getArgument();
importClass(Packages.ij.util.Tools);
argA = Tools.split(args, ":");
IJ.log(argA[0]);
IJ.log(argA[1]);

fpA = Tools.split(argA[0], "/");
path = "/";
for (i in fpA){
	if (i != (fpA.length - 1))
		path = path + fpA[i] + "/";
	else
		file = fpA[i];
}
traindata =argA[1];
IJ.log(path);
IJ.log(file);
IJ.log(traindata);


