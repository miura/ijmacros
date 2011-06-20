// analysis (dot-dot distance part)
/*
check numebr of dots for each channel. 

cho =1, ch1 =1 : connect. 

ch0 =2, ch1=1 or vice versa
connect the one that is larger.

ch0 =2, ch1 =2
first try connecting larger ones. 
then try owith closer one. 

if both cases much, then this should be OK. (first try with closer ones)

*/

var totalTimepoints = 46;
var connectArray =newArray(totalTimepoints*14); 3coords ch0, ch1 each, + distance for 2 sets (14) * timepoints. 


macro "connect dots in different channels"{
	LinkerCore();	
}

function LinkerCore(){
	if (nResults==0) exit("not measured??");
	for(i=0; i<connectArray.length; i++) connectArray[i] =-1;
	 DotLinker(totalTimepoints);
	for (i=0; i<totalTimepoints; i++){
		pstr = "time:" + i  + "\n"
			+ "   ch0: "	+ connectArray[i*14 ]
				+", "	+ connectArray[i*14 +1] 
 				+", "	+ connectArray[i*14 +2]
			+ "\n   ch1: "	+ connectArray[i*14 +3]
				+", "	+ connectArray[i*14 +3 +1] 
 				+", "	+ connectArray[i*14 +3 +2];
		if (connectArray[i*14 +7] !=-1) 
			pstr = pstr + "\n   ch0: "+   connectArray[i*14 +7]
				+", "+   connectArray[i*14 +7+1]
				+", "+   connectArray[i*14 +7+2]
				+ "\n   ch1: "+   connectArray[i*14 +7+3]
				+", "+   connectArray[i*14 +7+3+1]
				+", "+   connectArray[i*14 +7+3+2];
		print(pstr);
 
	}
}

function DotLinker(totaltimepoints){
	for (i=0; i<totaltimepoints; i++) {
		ch0dots = returnDotNumber(0, i);
		ch1dots = returnDotNumber(1, i);
		//print(i +":  Ch0 dots:", ch0dots, "- Ch1 dots:", ch1dots);
		
		if ((ch0dots != 0) && (ch1dots != 0)) {

			if ((ch0dots == 1) && (ch1dots == 1)) {
				StoreCoordinates(connectArray, i, 0, 0, 0);
				StoreCoordinates(connectArray, i, 1, 0, 0);
			} else {
				if ((ch0dots >= 2) && (ch1dots >= 2)) {
					flag = compare2x2(i);
					if (flag ==1) {
						StoreCoordinates(connectArray, i, 0, 0, 0);
						StoreCoordinates(connectArray, i, 1, 0, 0);
						StoreCoordinates(connectArray, i, 0, 1, 1);
						StoreCoordinates(connectArray, i, 1, 1, 1);
					} else {
						StoreCoordinates(connectArray, i, 0, 0, 0);
						StoreCoordinates(connectArray, i, 1, 0, 1);
						StoreCoordinates(connectArray, i, 0, 1, 1);
						StoreCoordinates(connectArray, i, 1, 1, 0);
					}
				} else {		//either one of them is only one. 
					flag = compare2x1(i);
					if (flag ==1) {
						StoreCoordinates(connectArray, i, 0, 0, 0);
						StoreCoordinates(connectArray, i, 1, 0, 0);
					} else {
						if (flag ==2) {
							StoreCoordinates(connectArray, i, 0, 0, 0);
							StoreCoordinates(connectArray, i, 1, 1, 0);
						} else {
							StoreCoordinates(connectArray, i, 0, 1, 0);
							StoreCoordinates(connectArray, i, 1, 0, 0);
						}
					}
				}
			}
		}

	}
}

function returnDotNumber(curchannel, tpoint){
	counter =0; 
	for (i=0; i<nResults;i++) {
		if ((getResult("timepoint",i)==tpoint) && (getResult("channel",i)==curchannel)) counter++;
	}
	return counter;
}

function returnDotIndex(curchannel, tpoint, dotID){
	retindex =0;
	for (i=0; i<nResults;i++) {
		if ((getResult("timepoint",i)==tpoint) && (getResult("channel",i)==curchannel) && (getResult("dotID",i)==dotID)) retindex=i;
	}
	return retindex ;
}

function StoreCoordinates(sA, timepoints, chrchannel, dotID, offset){
	key = timepoints * 14;
	index =  returnDotIndex(chrchannel, timepoints, dotID);
	sA[key+ offset*7 +chrchannel*3 ] =  getResult("x", index);
	sA[key+ offset*7+chrchannel*3+1] =  getResult("y", index);
	sA[key+ offset*7+chrchannel*3+2] =  getResult("z", index);
}

function compare2x2(timepoint){
	ch0id0 = returnDotIndex(0, timepoint, 0);
	ch0id1 = returnDotIndex(0, timepoint, 1);
	ch1id0 = returnDotIndex(1, timepoint, 0);
	ch1id1 = returnDotIndex(1, timepoint, 1);
	combi01 = returnDistance(ch0id0,  ch1id0) + returnDistance(ch0id1,  ch1id1);
	combi02 = returnDistance(ch0id0,  ch1id1) + returnDistance(ch0id1,  ch1id0);
	flag =0;
	if (combi01 < combi02 ) flag =1;
	else flag =2;
	return flag;
}

function compare2x1(timepoint){
	ch0dots = returnDotNumber(0, timepoint);
	ch1dots = returnDotNumber(1, timepoint);
	ch0id0 = returnDotIndex(0, timepoint, 0);
	ch1id0 = returnDotIndex(1, timepoint, 0);
	flag =0;
	if (ch0dots ==1) {
		ch1id1 = returnDotIndex(1, timepoint, 1);
		combi01 = returnDistance(ch0id0,  ch1id0) ;
		combi02 = returnDistance(ch0id0,  ch1id1) ;
		if (combi01<combi02) flag= 1;
		else flag = 2;
	} else {
		ch0id1 = returnDotIndex(0, timepoint, 1);
		combi01 = returnDistance(ch0id0,  ch1id0) ;
		combi02 = returnDistance(ch0id1,  ch1id0) ;
		if (combi01<combi02) flag= 1;
		else flag = 3;
	}
	return flag;
}

function returnDistance(index1, index2){
	sqd = pow(getResult("x", index1) - getResult("x", index2), 2) 
		+ pow(getResult("y", index1) - getResult("y", index2), 2) 
		+ pow(getResult("z", index1) - getResult("z", index2), 2);
	return pow(sqd, 0.5);
} 





 


