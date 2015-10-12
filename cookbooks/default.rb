include_recipe 'selinux::disabled'

service 'iptables' do
  action [:disable, :stop]
end
service 'ip6tables' do
  action [:disable, :stop]
end

execute 'change localtime to JST' do
  user 'root'
  command <<-EOC
  cp -p /usr/share/zoneinfo/Japan /etc/localtime
  echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock
  echo 'UTC=false' >> /etc/sysconfig/clock
  EOC
end

%w/epel-release nginx expect sqlite-devel/.each do |pkg|
  package pkg
end

execute 'install nodejs' do
  command <<-EOC
    yum -y install nodejs npm --enablerepo=epel
  EOC
end

service 'nginx' do
  action [:enable, :start]
end
