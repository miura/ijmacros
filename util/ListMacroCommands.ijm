str = File.openUrlAsString("http://rsb.info.nih.gov/ij/developer/macro/functions.html");
//print(str);
lineA = split(str, "\n");
for (i=0; i<lineA.length; i++){
	if (startsWith(lineA[i], "<b>")){
		endindex = indexOf(lineA[i], "</b>");
		comm = substring(lineA[i], 3, endindex);
		if (indexOf(comm, "(") > 0)
		{
			firstaftpare = substring(comm, indexOf(comm, "(")+1, indexOf(comm, "(")+2);
			//if (firstaftpare != "\""){
				comm = substring(comm, 0, indexOf(comm, "("));
			//}
		}
		print(comm );
	}
}