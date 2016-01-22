filepath = getArgument();
open(filepath);
//filename = File.getName(filepath);
filename = File.nameWithoutExtension;
dirname =  File.getParent(filepath);
print(filename)
print(dirname)
newfilepath = dirname + File.separator+ filename + "f1.tif"; 
run("Duplicate...", "f1");
saveAs("Tiff", newfilepath);
close();
close()
