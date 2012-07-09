# example of getting results table column max and min
from java.util import Collections

rt = ResultsTable.getResultsTable()
rt1 = rt.getColumn(5) # somehow 0 and 1 works but not the others in case of Z profile. 
print rt1[1]

print max(rt1)
print min(rt1)

#objmax = Collections.max(rt1);
#objmin = Collections.min(rt1);
#	    startendframeList.add(Integer.valueOf(objmin.toString()));
#	    startendframeList.add(Integer.valueOf(objmax.toString()));
