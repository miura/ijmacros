/***
Concatenates two stacks according to the land mark points stored within 
".points" file. ".points" files are the files created using [Name Landmarks and Register]
plugin in Fiji. 

Whatever the number of points recorded in the file, points average coordinate for 
each stack is used to calculate XY shift in position, and merges two stacks.

Kota Miura (miura@embl.de)
20140815 First version
*/

var Gtitle = "1";
var Rtitle = "2";

twoImageChoice();
selectWindow(Gtitle);
stack1 = getImageID();
dir1 = getInfo("image.directory");
ww1 = getWidth();
hh1 = getHeight();
dd1 = nSlices;
getPixelSize(unit, pixelWidth1, pixelHeight1);
selectWindow(Rtitle);
stack2 = getImageID();
dir2 = getInfo("image.directory");
ww2 = getWidth();
hh2 = getHeight();
dd2 = nSlices;
getPixelSize(unit, pixelWidth2, pixelHeight2);

img1 = getTifBasename(Gtitle);
img2 = getTifBasename(Rtitle);

pointfilepath1 = dir1 + img1 + ".points";
pointfilepath2 = dir2 + img2 + ".points";

print(pointfilepath1);
print(pointfilepath2);

p1A = getAveragePosition(pointfilepath1);
x1 = p1A[0] /pixelWidth1;
y1 = p1A[1] /pixelHeight1;

p2A = getAveragePosition(pointfilepath2);
x2 = p2A[0] / pixelWidth2;
y2 = p2A[1] / pixelHeight2;


//x1 = 0;
//y1 = 0;
//x2 = 10;
//y2 = 20;


left1 = 0;
right1 = ww1;
top1 = 0;
bottom1 = hh1;

left2 = x1 - x2;
right2 = left2 + ww2;
top2 = y1 - y2;
bottom2 = top2 + hh2;

//calculate coordinages according to the first image. 
if (left2 > 0){ //first image will be the base coordinate
	left3 = left1;
} else {	//second image will be the base
	left3 = left2;
}

if (right1 > right2){
	right3 = right1;
} else {
	right3 = right2;
}

if (top1 < top2){
	top3 = top1;
} else {
	top3 = top2;
}

if (bottom1 > bottom2){
	bottom3 = bottom1;
} else {
	bottom3 = bottom2;
}

ww3 = right3 - left3;
hh3 = bottom3 - top3;

if (left2 < 0){
	left1 = left2 * -1;
	left2 = 0;
}

if (top2 < 0){
	top1 = top2 * -1;
	top2 = 0;
}

newImage("combined", "8-bit black", ww3, hh3, dd1+dd2);
outid = getImageID();

print(left1, top1);
print(left2, top2);

setBatchMode(true);

for (i = 0; i < dd1; i++){
	selectImage(stack1);
	setSlice(i + 1);
	run("Select All");
	run("Copy");
	selectImage(outid);
	setSlice(i + 1);
	makeRectangle(left1, top1, ww1, hh1);
	run("Paste");
}

for (i = 0; i < dd2; i++){
	selectImage(stack2);
	setSlice(i + 1);
	run("Select All");
	run("Copy");
	selectImage(outid);
	setSlice(dd1 + i + 1);
	makeRectangle(left2, top2, ww2, hh2);
	print("second image rectangle", left2, top2, ww2, hh2);
	run("Paste");
}
setBatchMode(false);




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
	Dialog.addChoice("Top", wintitleA);
	Dialog.addChoice("Bottom", wintitleA);
 	Dialog.show();
 	//number1 = Dialog.getNumber();
 	//number2 = Dialog.getNumber();;
 	Gtitle = Dialog.getChoice();
	Rtitle = Dialog.getChoice();
	print(Gtitle + Rtitle);
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

// 20140815
// access .point files and get average coordinates
function getAveragePosition(path){
	s = File.openAsString(path);
	sA = split(s, "\n");
	count = 0;
	for (i = 0; i < sA.length; i++){
		if (startsWith(sA[i], "  <pointworld"))
			count++;
	}
	xA = newArray(count);
	yA = newArray(count);
	count = 0;
	for (i = 0; i < sA.length; i++){
		if (startsWith(sA[i], "  <pointworld")){
			aa = indexOf(sA[i], "x=");
			bb = indexOf(sA[i], "\" ", aa);
			cc = indexOf(sA[i], "y=", bb);
			dd = indexOf(sA[i], "\" ", cc);		
			xpos = substring(sA[i], aa+3, bb);
			ypos = substring(sA[i], cc+3, dd);
			print(xpos, ypos);
			xA[count] = parseFloat(xpos);
			yA[count] = parseFloat(ypos);
			count++;		
		}
	}
	Array.getStatistics(xA, xmin, xmax, xmean, xstdDev);
	Array.getStatistics(yA, ymin, ymax, ymean, ystdDev);
	print("Mean", xmean, ",", ymean);
	retA = newArray(xmean, ymean);
	return retA;
}

function getTifBasename(filename){
	ind1 = indexOf(filename, ".tif");
	basename = substring(filename, 0, ind1);
	return basename;
}

