from scala.tools.nsc import ScriptRunner
from scala.collection.immutable import List
from scala.tools.nsc import GenericRunnerSettings
from scala.tools.nsc import Settings
from ij import IJ
from java.io import PrintWriter
from scala import Option
from scala.tools.nsc.interpreter import IMain
from java.io import FileInputStream
from java.io import StringWriter
from java.io import InputStreamReader, BufferedReader
from org.apache.commons.io import IOUtils

def errors():
	IJ.log("error")

# Thread.currentThread().setContextClassLoader(IJ.getClassLoader());
#sr = ScriptRunner()

scriptfile = "/Users/miura/Dropbox/codes/mavenscala/ijscalascript/scripts/helloscript.scala"
inputStream = FileInputStream(scriptfile)
#writer = StringWriter()
#IOUtils.copy(inputStream, writer)
#theString = writer.toString()

#br= BufferedReader(InputStreamReader(inputStream))
#sb = StringBuilder()
#while (line = br.readLine()) != None:
#for line in br.readLine():
#	sb.append(line)
#System.out.println(sb.toString())
#br.close()

my_file = open(scriptfile,'r')
script = my_file.read()
   	
settings = Settings()
param = List.make(1, "true")
settings.usejavacp().tryToSet(param)
#PrintWriter stream = new PrintWriter(this.out);
stream = PrintWriter(System.out)
imain = IMain(settings, stream)
imain.interpret(script)

# following failed, since it uses commandline. 
#gensets = GenericRunnerSettings(errors())
#scriptArgs = List.make(1, "")
#runScript(settings: GenericRunnerSettings, scriptFile: String, scriptArgs: List[String])
#sr.runScript(settings, scriptfile, scriptArgs)
#sr.runScript(gensets, scriptfile, scriptArgs)

