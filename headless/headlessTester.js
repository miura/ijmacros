// test 1
/*
if (java.awt.headless) 
	IJ.log("1: headless"); 
else 
	IJ.log("1: with head");
*/
//test 2
if (System.getProperty("java.awt.headless"))
	IJ.log("0: headless"); 
else 
	IJ.log("0: with head");	


IJ.log("1: Headless mode: " + System.getProperty("java.awt.headless"));
//test 3

importClass(Packages.java.awt.GraphicsEnvironment);
ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
IJ.log("2: Headless mode: " + ge.isHeadless());