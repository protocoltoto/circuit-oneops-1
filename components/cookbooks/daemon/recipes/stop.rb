# Cookbook Name:: daemon
# Recipe:: stop
#
attrs = node.workorder.ci.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

service_type = nil
initService = `ls /ect/init.d/#{service_name}`
systemdService = `ls /usr/lib/systemd/system/#{service_name}.service`
if systemdService.include?("/usr/lib/systemd/system/#{service_name}.service")
	service_type = "systemd"
elsif initService.include?("/etc/init.d/#{service_name}")
	service_type = "init"
end

# stop daemon service when pattern has not been specified
ruby_block "stop #{service_name} service" do
	block do
    	Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    	shell_out!("service #{service_name} stop ", :live_stream => Chef::Log::logger)
	end
  	only_if { pat.empty? }
end

# stop daemon service when pattern has been specified
service "#{service_name}" do
	provider Chef::Provider::Service::Init if service_type == "init" && node[:platform_family].include?("rhel")
	pattern "#{pat}"
	action :stop
	only_if { !pat.empty? }
end
