install_file = "#{Chef::Config[:file_cache_path]}/TeamCityBuildAgent.zip"

remote_file install_file do
  source "http://#{node[:teamcity][:web_server]}/update/buildAgent.zip"
  not_if { ::File.exists? install_file }
end

windows_zipfile '/BuildAgent' do
  source install_file
  action :unzip
  not_if { ::File.exist?('/BuildAgent') }
end

unless File.exist?('c:\BuildAgent\conf\buildAgent.properties')
  template '/BuildAgent/conf/buildAgent.properties' do
    source 'buildAgent.properties.erb'
    variables(
      hostname: node[:hostname],
      web_server: node[:teamcity][:web_server]
    )
  end

  execute 'Install agent' do
    command 'service.install.bat'
    cwd '/BuildAgent/bin'
  end

  execute 'Configure agent windows service' do
    command "sc config TCBuildAgent obj= #{node[:teamcity][:agent][:username]} password= #{node[:teamcity][:agent][:password]} TYPE= own"
  end

  execute 'Start agent' do
    command 'service.start.bat'
    cwd '/BuildAgent/bin'
  end
end
