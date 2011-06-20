var str = "";
var separator = File.separator;
str = "";
dir = getDirectory("Choose a Directory ");
count = 1;

listFiles(dir);
//print(str);

folderA = split(str, ";");
for (i = 0; i< folderA.length; i++){
	if (separator == "\\") replace(folderA[i], "/", "\\");	//case windows
	else print(folderA[i]); 
}

function listFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")){
			listFiles(""+dir+list[i]);
			//print((count++) + ": " + dir + list[i]);  // printout folders
			str += dir + list[i] + ";";          		
		}   
     }
  }