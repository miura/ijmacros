// K_runOptionConstructorDemo.ijm
// Kota Miura (miura@embl.de)
//op = "number=20 smoothings=1 keep=20 a1=0.50 a2=0.90 dt=20 "+paratext+"";

kA = newArray("number", "smoothings", "keep", "a1", "a2","dt","edge");
vA = newArray(20, 1, 20, 0.50, 0.90, 20, 5); //default values
variKey = "edge";
variVal = 10;

print(ReturnOptionString(kA, vA, variableKey, variableVal));

function ReturnOptionString(keyA, valA, variableKey, variableVal){

	for (i = 0; i < keyA.length; i++)
		List.set(keyA[i], valA[i]);
	optlist = List.getList();
	//print(optlist);
	opt = ""
	for (i = 0; i < keyA.length; i++){
		if (keyA[i] != variableKey)
			opt = opt + keyA[i] + "=" + List.get(keyA[i])+ " ";
		else
			opt = opt + variableKey + "=" + variableVal+ " ";
	}
return opt;
}