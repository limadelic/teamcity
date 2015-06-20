### check if the Slave already exists and exit if it already it exists.
Chef::Log.info("TeamCity build agent service \"#{node[:teamcity][:servicename]}\" found. Skipping the install.") if ::Win32::Service.exists?("#{node[:teamcity][:servicename]}")
return if ::Win32::Service.exists?("#{node[:teamcity][:servicename]}")


install_file = "#{Chef::Config[:file_cache_path]}/TeamCityBuildAgent.zip"


# always download the buildagent.zip so we can update the buildagent to another TeamCity server.
remote_file install_file do
  source "http://#{node[:teamcity][:web_server]}/update/buildAgent.zip"
  action :create
end

windows_zipfile node[:teamcity][:buildAgent_path] do
  source install_file
  action :unzip
  not_if { ::File.exist?(node[:teamcity][:buildAgent_path]) }
end


  ### run a powershell script to do the LSA so we can run the service as a specific user
  cookbook_file node[:teamcity][:lsa_script_path] do
    source node[:teamcity][:lsa_script_src]
  end

  powershell_script "Add Services Log On Privileges" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOH
    $username = "#{node[:teamcity][:agent][:username]}"
    try {
      . #{node[:teamcity][:lsa_script_path]}
      [LsaWrapper.LsaWrapperCaller]::AddPrivileges($username, "SeServiceLogonRight")
    }
    catch [Exception] {
      Write-Error "Unable to Assign Service Logon Right.\n"
      Write-Error $_.Exception.Message
      exit 1
    }
    exit 0
    EOH
  end

properties_file = win_friendly_path(File.join(node[:teamcity][:buildAgent_path], "conf\\buildAgent.properties"))

template properties_file do
  source node[:teamcity][:buildAgent_properties_erb]    
  ## we don't need a variable block here since the ERB file contains the node attributes itself. This saves us from updating this recipe if we need to add more variable controls in the ERB file.
  not_if { ::File.exist?(properties_file) }
end

execute 'Install agent' do
  command 'service.install.bat'
  cwd '/BuildAgent/bin'
end

## The sc.exe requires ".\" for local accounts but for domain accounts such as "eng\yoguy" then we don't want ".\eng\yoguy".
service_username = node[:teamcity][:agent][:username]
if ( service_username !~ /\\/ )
  service_username = ".\\" + service_username
end


execute 'Configure agent windows service' do
  command "sc.exe config #{node[:teamcity][:servicename]} obj= \"#{service_username}\" password= \"#{node[:teamcity][:agent][:password]}\" TYPE= own"
end

execute 'Start agent' do
  command "net start #{node[:teamcity][:servicename]}"
  cwd '/BuildAgent/bin'
  action :run
end

