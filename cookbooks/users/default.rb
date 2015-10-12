require 'active_support/core_ext/object/blank'
require 'shellwords'
require "itamae/plugin/resource/ssh_key"

ALLOW_USERADD_OPTIONS = %w(
  base-dir home-dir defaults inactive gid
  groups skel key no-log-init create-home
  no-user-group non-unique password system
  root shell iud user-group user-group
  selinux-user
)

node[:base] ||= {}
node[:base][:user] ||= {}

node[:base][:users].each do |user, opt|

  # useradd command
  cmd = ["useradd"]

  useradd_options = opt.keys.select { |o| ALLOW_USERADD_OPTIONS.include?(o) }
  useradd_options.each do |uo|
    uo_str = "--#{uo}"
    uo_str << " #{Shellwords.escape(opt[uo])}" if !opt[uo].blank?
    cmd << uo_str
  end

  cmd << "#{user}"
puts cmd

  execute "add user #{user}" do
    command cmd.join(" ")
    not_if "id #{user}"
  end

  if opt.has_key?("github_user") ||
    opt.has_key?("key_file") ||
    opt.has_key?("ssh_keys")

    ssh_key user do
      github_user opt[:github_user]
      key_file opt[:key_file]
      ssh_keys opt[:ssh_keys]
    end
  end
end
