remote_file '/home/webservice/.bashrc' do
  owner 'webservice'
  group 'webservice'
end

directory '/opt/bastion' do
  action :create
  owner 'webservice'
  group 'webservice'
end

git '/opt/bastion' do
  repository 'https://github.com/wata-gh/bastion.git'
  user 'webservice'
end

directory '/opt/bastion/tmp/pids' do
  action :create
  owner 'webservice'
  group 'webservice'
end

directory '/opt/bastion/tmp/socket' do
  action :create
  owner 'webservice'
  group 'webservice'
end

gem_package 'bundler'

execute 'setup bastion' do
  user 'webservice'
  cwd '/opt/bastion'
  command <<-EOC
    source /home/webservice/.bashrc
    script/bootstrap
    bundle exec rake db:create
    bundle exec rake db:migrate
  EOC
  not_if 'test -f bastion_production.db'
end

template '/opt/bastion/config.yml' do
  owner 'webservice'
end

remote_file '/etc/init.d/bastion_unicorn' do
  mode '755'
end

service 'bastion_unicorn' do
  action [:enable, :start]
end

node[:mod_ssl] ||= {}
node[:mod_ssl][:version] ||= '2.8.31-1.3.41'
MOD_SSL_VER = node[:mod_ssl][:version]
execute 'download mod_ssl' do
  user 'webservice'
  command <<-EOC
    curl -o#{MOD_SSL_VER}.tar.gz http://www.modssl.org/source/mod_ssl-#{MOD_SSL_VER}.tar.gz
    tar zxvf #{MOD_SSL_VER}.tar.gz
  EOC
end

node[:cert] ||= {}
pass = node[:cert][:password] || 'bastion'
execute 'generate CA' do
  user 'webservice'
  cwd '/opt/bastion/ccert'
  command <<-EOC
    openssl genrsa -des3 -passout pass:#{pass} -out ca.key -rand rand.dat 2048
    openssl req -new -x509 -days 365 -key ca.key -passin pass:#{pass} -out ca.crt \
      -subj "/C=JP/ST=Tokyo/L=Chiyoda-Ku/O=/OU=/CN=/"
    openssl genrsa -des3 -passout pass:#{pass} -out server.key -rand rand.dat 2048
    openssl req -new -key server.key -passin pass:#{pass} -out server.csr \
      -subj "/C=JP/ST=Tokyo/L=Chiyoda-Ku/O=/OU=/CN=#{node[:cert][:common_name]}/"
    cp server.key server.key.bak
    openssl rsa -in server.key.bak -passin pass:#{pass} -out server.key
  EOC
  not_if 'test -f server.key'
end

template '/home/webservice/make_cert.exp' do
  owner 'webservice'
  group 'webservice'
end

execute 'sign cert' do
  user 'webservice'
  cwd '/opt/bastion/ccert'
  command <<-EOC
    expect -f /home/webservice/make_cert.exp /home/webservice/mod_ssl-#{MOD_SSL_VER}/pkg.contrib/sign.sh server.csr
  EOC
  not_if 'test -f server.crt'
end

template '/etc/nginx/conf.d/ssl.conf' do
  owner 'root'
  notifies :reload, 'service[nginx]'
end
