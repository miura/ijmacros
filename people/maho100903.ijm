var imagenumbering = 0;

macro "Duplicate this Slice and EC [F1]" {
	run("Duplicate...", "title=sampleMovie"+imagenumbering);
	run("Enhance Contrast", "saturated=0.35");
	imagenumbering++;
}

var Gtitle="ig1";	
var Rtitle="ig2";	


macro "Merge 2ch [F2]"{
	
	twoImageChoice();
	op = "red="+Rtitle+" green="+Gtitle+" blue=*None* gray=*None* keep";
	run("Merge Channels...", op);

}

//Kota: choosing two images among currently opened windows
function twoImageChoice() {
	imgnum=Wincount();
	imgIDA=newArray(imgnum);
	wintitleA=newArray(imgnum);

	CountOpenedWindows(imgIDA);
	WinTitleGetter(imgIDA,wintitleA);

 	Dialog.create("select two images");
	//Dialog.addNumber("number1:", 0);
 	//Dialog.addNumber("number2:", 0);
	Dialog.addChoice("Ch Red", wintitleA);
	Dialog.addChoice("Ch Green", wintitleA);
 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 = Dialog.getNumber();;
 	Rtitle = Dialog.getChoice();
	Gtitle = Dialog.getChoice();
	print("red:"+Rtitle + " green:"+Gtitle);
}

function CountOpenedWindows(imgIDA) {
	imgcount=0;
	for(i=0; i>-2000; i--) {
		if(isOpen(i)) {
			imgIDA[imgcount]=i;
			imgcount++;
		}
	}
}

function Wincount() {
	wincounter=0;
	for(i=0; i>-2000; i--) {
		if(isOpen(i)) {
			wincounter++;
			print(i);
		}
	}
	return wincounter;
}

function WinTitleGetter(idA,titleA) {
	for (i=0;i<idA.length;i++) {
		selectImage(idA[i]);
		titleA[i]=getTitle();
	}
}

