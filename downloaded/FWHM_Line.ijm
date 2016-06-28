//Measure FWHM from intensity profile using Gaussian Fitting
//Image must have aspect ratio of one
//Version 1: 8 Mar 2011, John Lim, IMB
//Version 2; 9 Mar 2011, Send FWHM to a table, John Lim, IMB
//Version 3; 11 Mar 2011, Rename the fitting graph, John Lim, IMB

getPixelSize(unit, pixelWidth, pixelHeight);
getDimensions(width, height, channels, slices, frames);

if(pixelWidth!=pixelHeight){
	exit("Please select an image with pixel aspect ratio of one.")
}

id0=getImageID();
//roiManager("Add");

if(selectionType()!=5){
	exit("Support only straight line");
}
getSelectionBounds(a, b, c, d);
line=""+a+" "+b+" "+c+" "+d;
if(channels>1){
	Stack.getPosition(channel, dummy, dummy);
	line="Ch"+channel+" "+a+" "+b+" "+c+" "+d;
}

Y=getProfile();
len=Y.length;

X=newArray(len);
for(i=0;i<len;i++){
	X[i]=i*pixelHeight;
}

Fit.doFit("Gaussian", X, Y);
r2=Fit.rSquared;
if(r2<0.9){
	showMessage("Warming: Poor Fitting",r2);
}
Fit.plot();
if(isOpen("y = a + (b-a)*exp(-(x-c)*(x-c)/(2*d*d))")){
	selectWindow("y = a + (b-a)*exp(-(x-c)*(x-c)/(2*d*d))");
	rename(line);
}
sigma=Fit.p(3);
FWHM=abs(2*sqrt(2*log(2))*sigma);
myTable(line,FWHM,unit);
selectImage(id0);
selectWindow("FWHM");

function myTable(a,b,c){
	title1="FWHM";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c);
	}
	else{
   		run("Table...", "name="+title2+" width=300 height=200");
   		print(title2, "\\Headings:Line\tFWHM\tUnit");
   		print(title2, a+"\t"+b+"\t"+c);
	}
}

--
ImageJ mailing list: http://imagej.nih.gov/ij/list.html
