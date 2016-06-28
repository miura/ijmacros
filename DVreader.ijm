// Importing Deltavision .dv file (DVreader.txt)
//	Kota Miura (miura@embl.de)
//20050513
// Header size of .dv file is calculated from the width and height of the frame, frame number. 
// General rule is:	static header length 528pixels (1056bytes) + dynamic headers (80 pixels/frame, 160 bytes/frame)
//		information for each frame is contained in the first 20 pixels (40bytes) and header is terminated at 
//		multiples of 512 pizels (1028bytes).
//		* header length is somehow related to the number contained in [46,0] but there are exceptions
//			(header length=((lengthPrimer/512/2+1)*512*2))	
//		[0,0] width
//		[2,0] height
//		[4,0] frames
//		[6,0] depth (z)
//		[90,0] time-points
//		[98,0] channels
//UNSOLVED PROBLEM: if the sequence is the one that was force-terminated during the acquisition, header length is shorter than
// the value calculated by the above method. The sequence will not be imported properly. 
// 050526	added second method (estimate from primer). 
// 050712	depends only on headerlength primer; 4bytes (32bit signed integer);
//050713	.r3d loader (Big endian)
//070612	"Read .dv header" added. Reads out only the header info, so that the accidentally terminated file can be loaded from [import-> Raw]

var headerlength=512;
var impH=100;
var impW=100;
var framenumber=1;
var pathname="";
var filename="";
var timepoints=10;
var channels=1;
var zslices=1;

var hexstr0="";
var hexstr1="";
var hexstr2="";
var hexstr3="";

var hexstrtop="";
var hexstrbot="";

function DvImport(HeaderMethod,byteOrder) { 
	requires("1.34j");
	DVHeaderReader(HeaderMethod,byteOrder);
	if (byteOrder==0){
		imp_para=" image=[16-bit Unsigned] width="+impW+" height="+impH+" offset="+headerlength+" number="+framenumber+" gap=0  little-endian "; 
	}
	else {
		imp_para=" image=[16-bit Unsigned] width="+impW+" height="+impH+" offset="+headerlength+" number="+framenumber+" gap=0 "; 
	}		
	open_para="open="+pathname+filename+imp_para;
	run("Raw...", open_para);	
}

function DVHeaderReader(HeaderMethod,byteOrder) {
	setBatchMode(true);
	if (byteOrder==0) {
		imp_para=" image=[16-bit Unsigned] width=110 height=1 offset=0 number=1 gap=0  little-endian "; 
	}
	else {
		imp_para=" image=[16-bit Unsigned] width=110 height=1 offset=0 number=1 gap=0 "; 
	}
	open_para="open="+imp_para;
	run("Raw...", open_para);
	if (byteOrder==0) {
		impW=getPixel(0,0);
		impH=getPixel(2,0);
		framenumber=getPixel(4,0);
		lengthPrimer=getPixel(46,0);
		lengthPrimer2=getPixel(47,0);
		timepoints=getPixel(90,0);
		channels=getPixel(98,0);
	} else {
		impW=getPixel(1,0);
		impH=getPixel(3,0);
		framenumber=getPixel(5,0);
		lengthPrimer=getPixel(46,0);
		lengthPrimer2=getPixel(47,0);
		timepoints=getPixel(90,0);
		channels=getPixel(98,0);
	}


	if (HeaderMethod==3) headerlength=Header3(framenumber,impW);
	if (HeaderMethod==2) headerlength=Header2(lengthPrimer);
	if (HeaderMethod==1) {
		if (byteOrder==0) {
			headerlength=Header1(lengthPrimer,lengthPrimer2);
		} else {
			headerlength=Header1BigEnd(lengthPrimer,lengthPrimer2);
		}
	}
	zslices=framenumber/timepoints/channels;

	pathname=getDirectory("image");
	filename=getTitle();
	
	close();
	setBatchMode(false);

	print("");
	print(".dv importer "+pathname+filename);
	print("Header Length:"+headerlength);
	print("Channels:"+channels+"  Time Points:"+timepoints+"  Z slices:"+zslices);
	print("width:"+impW+"  height:"+impH+"  Frames: "+framenumber);
}


function Header1(lengthPrimer,lengthPrimer2){
	extendedHeader=TwoPixelDec2Hex(lengthPrimer,lengthPrimer2);
	totalHeader=1024+extendedHeader;
	totalHeaderPix=totalHeader/2;
	return (totalHeader);
}

function Header1BigEnd(lengthPrimer,lengthPrimer2) {
	extendedHeader=TwoPixelDec2HexBigEndian(lengthPrimer,lengthPrimer2);
	totalHeader=1024+extendedHeader;
	totalHeaderPix=totalHeader/2;
	return (totalHeader);
}

//not working sometimes
function Header2(lengthPrimer){
	return ((lengthPrimer/512/2+1)*512*2);
}

function Header3(framenumber,impW){
	temp1=528+80*framenumber;
	bit16=floor(temp1/512);
	restHL=temp1-bit16*512;
	//bit16=floor(temp1/512);

	if (restHL>50) {
		headerlen=512*(bit16+1)*2;
	} else {
		headerlen=512*bit16*2;
	}
	return (headerlen);
}



//050712
macro "Import .dv  method1 [f1]" {
	//DVHeaderReader();
	DvImport(1,0);
}

macro "Import .r3d  method1 [f2]" {
	//DVHeaderReader();
	DvImport(1,1);
}

macro "-" {}

//070612
macro "Read .dv Header" {
	DVHeaderReader(1,0);
}

//macro "Import .dv  method2 old" {
////	DVHeaderReader();
//	DvImport(2,0);
//}

//macro "Import .dv  method3 old" {
//	DVHeaderReader();
//	DvImport(3,0);
//}

//macro "Print Header" {
//	printheaderCore();
//}
function printheaderCore() {
	pixelnum=getNumber("How Many Pixels?",4096);
	ww=getWidth();
	wh=getHeight();
	rownumber=floor(pixelnum/ww)+1;
	if (ww<pixelnum) {
		for (j=0;j<=rownumber;j++) {
			if (j==rownumber) {
				for (i=0;i<(pixelnum-ww*(rownumber-1));i++) {
					currentpix=getPixel(i,j);
					print(currentpix);
				}

			} else {
				for (i=0;i<ww;i++) {
					currentpix=getPixel(i,j);
					print(currentpix);
				}
			}
		}
	} else {
		for (i=0;i<pixelnum;i++) {
			currentpix=getPixel(i,0);
			print(currentpix);
		}
	}

}

//050712	conversion of two pixel values to a 4byte hex number. 
//macro "print hex test" {
//	//Dec2Hex(200);
//	resultdec=TwoPixelDec2Hex(20480,18);
//	print(resultdec);
//}

//050712 Reinterprets two values in 2 pixels positions to a 4byte integer.
function TwoPixelDec2Hex(firstpix,secondpix) {
	Dec2Hex1(firstpix);
	Dec2Hex2(secondpix);
	totalHex=""+hexstr0+hexstr1+hexstr2+hexstr3;
	return(hexs2dec(totalHex));
}

//050713 Reinterprets two values in 2 pixels positions to a 4byte integer.
// big-endian byte order
function TwoPixelDec2HexBigEndian(firstpix,secondpix) {
	Dec2HexBE1(firstpix);
	Dec2HexBE2(secondpix);
	totalHex=""+hexstr0+hexstr1+hexstr2+hexstr3;
	return(hexs2dec(totalHex));
}

//050712
function Dec2Hex1(dec) {
	hexedstr=leftPad(toHex(dec), 4);
	print(hexedstr);
	hexstr2=""+substring(hexedstr,0,2);
	hexstr3=""+substring(hexedstr,2,4);
//	hexed=0+hexedstr;
//	hextop=floor(hexed/100);
//	hexbot=hexed-100*hextop;
//	print(hexstr2);
//	print(hexstr3);
}

//050712
function Dec2Hex2(dec) {
	hexedstr=leftPad(toHex(dec), 4);
	print(hexedstr);
	hexstr0=""+substring(hexedstr,0,2);
	hexstr1=""+substring(hexedstr,2,4);
//	hexed=0+hexedstr;
//	hextop=floor(hexed/100);
//	hexbot=hexed-100*hextop;
//	print(hexstr0);
//	print(hexstr1);
}

//050713 big-endian
function Dec2HexBE1(dec) {
	hexedstr=leftPad(toHex(dec), 4);
	print(hexedstr);
	hexstr0=""+substring(hexedstr,0,2);
	hexstr1=""+substring(hexedstr,2,4);
}

//050712
function Dec2HexBE2(dec) {
	hexedstr=leftPad(toHex(dec), 4);
	print(hexedstr);
	hexstr2=""+substring(hexedstr,0,2);
	hexstr3=""+substring(hexedstr,2,4);
}


//050712 copied from PerkElnmer Opener
function leftPad(n, width) {
    s =""+n;
    while (lengthOf(s)<width)
        s = "0"+s;
    return s;
}

//050712 copied from PerkElnmer Opener
//041025 Kota hexadecimal string to decimal number
function hexs2dec(hexs) {
	dec=0;
	for(i=0;i<lengthOf(hexs);i++)	{
		s_unic=charCodeAt(hexs, i);
		if (s_unic<58) {
			digit=s_unic-48;//0=unicode 48
		} else	{
			digit=s_unic-96+9;//a=unicode 97
		}
		dec+=pow(2,4*(lengthOf(hexs)-i-1))*digit;
	}
	return dec;
}
