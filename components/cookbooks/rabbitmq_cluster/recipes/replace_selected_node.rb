
include_recipe "rabbitmq_cluster::app_stop"

node.cloud_ids.each do |id|
	ruby_block "break cluster" do
		block do
			Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
			ip_addresses = node.workorder.payLoad.RequiresComputes.select { |c| c[:ciName].split("-")[1] == id }
			ip_addresses.each do |ip|
				ssh_cmd = "ssh -i /tmp/ssh/key_file_#{id} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@#{ip[:ciAttributes][:private_ip]} "
				break_cmd = "rabbitmqctl forget_cluster_node rabbit@#{node.current_hostname}"
				execute_cmd = shell_out!("#{ssh_cmd} \"#{break_cmd}\"", :live_stream => Chef::Log::logger)
				Chef::Log.info "output is: #{execute_cmd.stdout}"
			end
		end
	end
end

node.hostnames.each do |host|
	ruby_block "joining #{node.current_hostname} with #{host}" do
		block do
			Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
			shell_out!("rabbitmqctl join_cluster rabbit@#{host}", :live_stream => Chef::Log::logger)
		end
		not_if { host == node.current_hostname }
	end
end

include_recipe "rabbitmq_cluster::app_start"