'''
try with a higher level access
'''

from tango.gui import Connector, Core
from tango.mongo import MongoConnector

usr = "testuser"

#core = Core()
#connector = Connector(core)
#while True:
#	try:
Core.mongoConnector = MongoConnector('localhost')
#user = Core.mongoConnector.setUser("miura", False)
user = Core.mongoConnector.setUser(usr, True)

if user == None:
	print "user is none"
else:
	print Core.mongoConnector.isConnected()
	Core.mongoConnector.close()
	print Core.mongoConnector.isConnected()

# there should be then the floowing method, which sets user again	
user2 = Core.mongoConnector.setUser(usr, False)
if user2 == None:
	print "user2 is none"
else:
	print "user2 is present"

'''
    private void setUser(String usr) {
        if (utils.contains(usernames, usr, true)) {
            usernames.setSelectedItem(usr);
        }
        BasicDBObject user = Core.mongoConnector.setUser(usr, false);
        if (user != null) {
            currentUser = usr;
            Object userHost = user.get("options_" + this.getHost());
            if (userHost == null) {
                userHost = new BasicDBObject();
                user.append("options_" + this.getHost(), userHost);
            }
            options.dbGet((BasicDBObject) userHost);
            SystemEnvironmentVariable mongoUser = new SystemEnvironmentVariable("mongoUser", usr, false, false, false);
            mongoUser.writeToPrefs();
            core.connect();
            toggleEnableButtons(true, true);
        } else {
            currentUser = null;
            core.disableTabs();
            toggleEnableButtons(true, false);
        }
    }
'''