
default.teamcity.buildAgent_path = 'c:/BuildAgent'
default.teamcity.servicename = "TCBuildAgent"
default.teamcity.lsa_script_src = "lsawrapper.ps1"
default.teamcity.lsa_script_path = File.join(Chef::Config[:file_cache_path], "lsawrapper.ps1")
default.teamcity.buildAgent_properties_erb = 'buildAgent.properties.erb'
 
# You must provide the web server here or in a Chef role
#default.teamcity.web_server =

default.teamcity.hostname = ENV['COMPUTERNAME']
default.teamcity.workDir = '../work'
default.teamcity.tempDir = '../temp'
default.teamcity.systemDir = '../system'
default.teamcity.ownPort = '9090'

