// for running radial profile plugin silently. 
// works only with the plugin installed. 
// http://imagej.nih.gov/ij/plugins/radial-profile.html

importClass(Packages.java.lang.Thread);
importClass(Packages.ij.Macro);
imp = IJ.getImage();
options = "x=141 y=106 radius=123.50";
thread = Thread.currentThread();
original_name = thread.getName();
thread.setName("Run$_my_batch_process");
Macro.setOptions(Thread.currentThread(), options);
rp = IJ.runPlugIn(imp, "Radial_Profile", "");