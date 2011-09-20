/*
Example of using Apache Common Math to do general statistics. 
Kota Miura (miura@embl.de)
*/
importClass(Packages.org.apache.commons.math.stat.StatUtils);
importClass(Packages.org.apache.commons.math.stat.descriptive.DescriptiveStatistics);
 
test = [1 , 3, 4, 8, 100];
IJ.log(test[2]);
mn = StatUtils.mean(test);
IJ.log(mn);

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