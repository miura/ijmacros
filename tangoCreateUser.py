'''
A script for directly accedssing mongoDB to add a user. 
The purpose is to test GUI user selection procedure and find out the problem of "serverUsed" error.

Kota Miura (miura@embl.de)
'''
from com.mongodb import MongoClient
from com.mongodb import BasicDBObject
from tango.util import SystemMethods

# from here, based on MongoConnector.setUser()

prefix = "tango"
adminName = prefix+"_admin"
defaultHost_DB="localhost"
host = defaultHost_DB

m = MongoClient(host)
dbnames = m.getDatabaseNames()
for dbname in dbnames:
	print dbname
if dbnames.contains(adminName):
   admin=m.getDB(adminName)
else:
   admin=m.getDB(adminName)

adminUser=admin.getCollection("user")
adminProject=admin.getCollection("dbnames")
help=admin.getCollection("help")


username = "checkadduser2"
settingsDB = "test_"+username+"_settings"
if dbnames.contains(settingsDB):
	print settingsDB+" exits already"
else:
	adminUser.save(BasicDBObject("name", username).append("settingsDB", settingsDB))
	# here, user object (and instance of BasiceDBObject) is generated. 
	user = adminUser.findOne( BasicDBObject("name", username))
	adminProject.createIndex( BasicDBObject("user_id", 1).append("name", 1))
	adminUser.createIndex( BasicDBObject("name", 1))
	help.createIndex( BasicDBObject("container", 1).append("element", 1))
	print "...db created"
	userId=user.get("_id")
	settings = m.getDB(user.getString("settingsDB"))
	if settings==None:
		IJ.log("settings null")
	if not settings.collectionExists("nucleus"):
		settings.createCollection("nucleus", BasicDBObject())
	if not settings.collectionExists("channel"):
		settings.createCollection("channel", BasicDBObject())
	nucleusSettings = settings.getCollection("nucleus")
	channelSettings = settings.getCollection("channel")	
		
		