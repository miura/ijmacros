from com.mongodb import MongoClient
from com.mongodb import BasicDBObject
prefix = "tango"
adminName = prefix+"_admin"
defaultHost_DB="localhost"
host = defaultHost_DB

m = MongoClient(host)
dbnames = m.getDatabaseNames()
for dbname in dbnames:
	print dbname