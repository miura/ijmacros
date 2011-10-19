macro "Particle track 3D" {
	run("ParticleTracker 3D", "radius=3 cutoff=0 percentile=0.10000 preprocessing=none");
}


function BubbleSortWithKey(keyA, slaveA) {
	k=keyA.length-1;
	while (k>=0) {
		j=-1;
		for (i=1; i<=k; i++) { 
			if (keyA[i-1] > keyA[i]) {
				j = i-1;
				swap = keyA[j];
				keyA[j] = keyA[i];
				keyA[i] = swap;	

				swap = slaveA[j];
				slaveA[j] = slaveA[i];
				slaveA[i] = swap;
			}
		}
		k = j;
	}
}

macro "test sort" {
	aA = newArray(10, 2, 8, 6, 4);
	bA = newArray(0, 1, 2, 3, 4);
	BubbleSortWithKey(aA, bA);
	print("sorting");
	for (i=0; i<aA.length; i++) print(aA[i]+"    :"+bA[i]);
}

macro "find opt intensity" {
	trackCoreProcess(2, 0.1);
	ChangeTxtName(1);

	trackCoreProcess(2, 0.2);
	ChangeTxtName(2);

	trackCoreProcess(2, 0.3);
	ChangeTxtName(3);

	trackCoreProcess(2, 0.4);
	ChangeTxtName(4);

	trackCoreProcess(2, 0.5);
	ChangeTxtName(5);
//
	trackCoreProcess(3, 0.1);
	ChangeTxtName(6);

	trackCoreProcess(3, 0.2);
	ChangeTxtName(7);

	trackCoreProcess(3, 0.3);
	ChangeTxtName(8);

	trackCoreProcess(3, 0.4);
	ChangeTxtName(9);

	trackCoreProcess(3, 0.5);
	ChangeTxtName(10);

//
	trackCoreProcess(4, 0.1);
	ChangeTxtName(11);

	trackCoreProcess(4, 0.2);
	ChangeTxtName(12);

	trackCoreProcess(4, 0.3);
	ChangeTxtName(13);

	trackCoreProcess(4, 0.4);
	ChangeTxtName(14);

	trackCoreProcess(4, 0.5);
	ChangeTxtName(15);

//
	trackCoreProcess(5, 0.1);
	ChangeTxtName(16);

	trackCoreProcess(5, 0.2);
	ChangeTxtName(17);

	trackCoreProcess(5, 0.3);
	ChangeTxtName(18);

	trackCoreProcess(5, 0.4);
	ChangeTxtName(19);

	trackCoreProcess(5, 0.5);
	ChangeTxtName(20);

//
	trackCoreProcess(6, 0.1);
	ChangeTxtName(21);

	trackCoreProcess(6, 0.2);
	ChangeTxtName(22);

	trackCoreProcess(6, 0.3);
	ChangeTxtName(23);

	trackCoreProcess(6, 0.4);
	ChangeTxtName(24);

	trackCoreProcess(6, 0.5);
	ChangeTxtName(25);

//
	trackCoreProcess(8, 0.1);
	ChangeTxtName(26);

	trackCoreProcess(8, 0.2);
	ChangeTxtName(27);

	trackCoreProcess(10, 0.1);
	ChangeTxtName(28);

	trackCoreProcess(10, 0.2);
	ChangeTxtName(29);

	trackCoreProcess(12, 0.1);
	ChangeTxtName(30);

	trackCoreProcess(12, 0.2);
	ChangeTxtName(31);

}
function trackCoreProcess(radi, ptl){
	op = "radius="+radi+" cutoff=0 percentile="+parseFloat(ptl)+" threshold=Percentile preprocessing=[Laplace Operation] link=1 displacement=8";
	run("ParticleTracker 3D", op);
}

macro "testCore"{
	trackCoreProcess(3, 0.1);
	ChangeTxtName(10000);
}


macro "test path" {
	ChangeTxtName(1);
}

function ChangeTxtNameold(numbering){
	cdir =getDirectory("image");
	imgname = getTitle();
	autoname = "\\ParticleTracker3DResults\\"+imgname+"PT3D.txt";
	fpath = cdir+autoname;
	print(fpath);
	if (File.exists(fpath)) print("does");
	newname ="\\ParticleTracker3DResults\\"+imgname+"PT3D"+"_"+numbering+".txt";
	fpathNew = cdir+newname;
	File.rename(fpath , fpathNew );
}

//for newwer ImageJ
function ChangeTxtName(numbering){
	cdir =getDirectory("image");
	imgname = getTitle();
	autoname = "\ParticleTracker3DResults\\"+imgname+"PT3D.txt";
	fpath = cdir+autoname;
	print(fpath);
	if (File.exists(fpath)) print("does");
	newname ="\ParticleTracker3DResults\\"+imgname+"PT3D"+"_"+numbering+".txt";
	fpathNew = cdir+newname;
	File.rename(fpath , fpathNew );
}

macro "find opt intensity short" {


	trackCoreProcess(3, 0.5);
	ChangeTxtName(10);

//
	trackCoreProcess(4, 0.1);
	ChangeTxtName(11);


}
