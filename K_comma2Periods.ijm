// comma2Periods.ijm
// Kota Miura (miura@embl.de) 20110711
// Converts text file, decimal points in comma (German tradition) to periods
// and save the converted textfile with suffix "mod"

str = File.openAsString("");
curdir = File.directory;
curfile = File.name;
curfileNoExt = File.nameWithoutExtension;
newname = curfileNoExt + "mod.txt";
newstr = replace(str, ",", ".");
File.saveString(newstr, curdir + newname);