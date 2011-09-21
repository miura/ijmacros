/*
Example of using Apache Common Math to do general statistics. 
Kota Miura (miura@embl.de)
*/

//first example, using static methods "StatUtils". 
importClass(Packages.org.apache.commons.math.stat.StatUtils);
 
test = [1 , 3, 4, 8, 100];
IJ.log(test[2]);
mn = StatUtils.mean(test);
IJ.log(mn);

//above static method is limited with number of things that could be done. 
//use DescriptiveStatistics then (but consumes more memory)
importClass(Packages.org.apache.commons.math.stat.descriptive.DescriptiveStatistics);

stats = new DescriptiveStatistics();

// Add the data from the array
for(i = 0; i < test.length; i++) {
        stats.addValue(test[i]);
}

// Compute some statistics
mean = stats.getMean();
std = stats.getStandardDeviation();
median = stats.getPercentile(50);

IJ.log(mean);
IJ.log(std);