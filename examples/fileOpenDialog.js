//example script for file opening dialog
//Kota miura

importPackage(Packages.ij.io);

od = new OpenDialog("Choose Data File", null);
srcdir = od.getDirectory();
filename = od.getFileName();
fullpath = java.lang.String(srcdir+filename);