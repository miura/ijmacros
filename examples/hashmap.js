
importClass(Packages.java.util.HashMap)
	
	javamap = HashMap();
	javamap.put("test", 1);
	javamap.put("test2", 2);
	javamap.put("test3", 3);
	IJ.log(javamap.get("test2"));
	var iter = javamap.entrySet().iterator();
	while (iter.hasNext)
		//IJ.log(iter.next().getValue());
		IJ.log(iter.next());
	IJ.log("--");
