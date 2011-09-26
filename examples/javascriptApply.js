/* javascript appy and call usage

http://stackoverflow.com/questions/5427254/javascript-math-parameter-passing-arrays-and-the-apply-method

this is pretty tough....
some more links
http://ejohn.org/apps/learn/#41
http://dev-tricks.com/trickscall-and-apply-methods-in-javascript/

*/

//example here
//http://generation1991.g.hatena.ne.jp/iskwn/20100204/1265262870
/* 
function inverse() {
    this.a *= -1;
    this.b *= -1;
}

var data = { a: 10, b: 10 }

inverse.apply(data, null);

IJ.log(data.a) // -10

*/

/*
var x = 'test',
    obj = { x: 'value' };
function bar(){
	IJ.log(this.x);
}
bar(); // log 'test'
bar.call(obj);  // log 'value'
bar.apply(obj); // log 'value'
*/
// above seems to be clear, call and apply substitutes target object. 


	var x = 'test',
		y = 'name',
		z = Array(0, 1, 2, 3, 4),
		obj = { x: 'value' };

	//function bar(arg1, arg2){
	function bar(arg1){

		//IJ.log(this.x + arg1 + arg2);
		IJ.log(this.x + arg1);
	}

	bar.call(obj, z, y); // log 'value', 'test', 'name'
	bar.apply(obj, [z, y]); // log 'value', 'test', 'name'