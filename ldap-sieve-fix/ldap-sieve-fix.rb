#! /usr/bin/ruby -w
require 'rubygems'
require 'net-ldap'

#
# LDAP-Sieve Fix
# Fetches Mailnames and creates symlinks for them - simply fire and forget
#
# Licence: BSD 2-Clause
# Contributor: Daniel Schweighöfer (acid)

host = 'localhost'
port = 389
username = 'cn=admin, dc=example, dc=org'
password = 'changeme'
filter = Net::LDAP::Filter.eq("objectClass", "inetOrgPerson")
treebase = "dc=example,dc=org"

basedir = "/path/to/sievescripts/directory"
suffix = ""

ldap = Net::LDAP.new :host => host,
  :port => port,
  :auth => {
    :method => :simple,
    :username => username,
    :password => password
  }

result = []
ldap.search(:base => treebase, :filter => filter) do |entry|
  uid = mail = nil
  entry.each do |attribute,value|
    uid = value.first if attribute == :uid
    mail = value if attribute == :mail
  end
  mail = mail.map do |a|
    a = a.split('@').first
  end
  mail.delete uid
  result.concat [{ :uid => uid, :mails => mail}] if mail.length > 0
end

puts "#{result.length} objects with multiple mail addresses found. Doing the linking..."

#result.each do |u|
#  File.new "#{basedir}/#{u[:uid]}", "w"
#end

result.each do |user|
  useruid = user[:uid]
  user[:mails].each do |mail|
    File.symlink "#{basedir}/#{useruid}", "#{basedir}/#{mail}"
  end
end
