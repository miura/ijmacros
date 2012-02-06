/* Xavier, helping his ImageJ macro. 
20110621 Kota
*/

Xmax=5;
Ymax=10;
origID = getImageID();
newImage("processed", "32-bit Black", getWidth(), getHeight, 1);
destID = getImageID();
setBatchMode(true);
for (j=0;j<Ymax;j+=1){
	for (i=0;i<Xmax;i+=1){
		selectImage(origID);
		run("Specify...", "width=11 height=11 x="+i+" y="+j+" oval");
		run("Copy");
		run("Internal Clipboard");
		run("Rotate... ", "angle=15 grid=1 interpolation=None");
		run("Copy");
		close();
		selectImage(destID);
		run("Specify...", "width=11 height=11 x="+i+" y="+j+" oval");
		setPasteMode("Add");
		run("Paste");
					
//		run("Specify...", "width=10 height=10 x=i y=Ymax oval");
//		run("Rotate... ", "angle=-15 grid=1 interpolation=None");
	}
}
setBatchMode("exit and display");
