#/usr/bin/ruby -w

require 'rubygems'
require 'net/ldap'
require 'highline/import'
require 'sinatra'

username = ask("Enter username: ") { |q| q.echo = true }
password = ask("Enter password: ") { |q| q.echo = false }

# Setup some default ldap settings
ldap_args = {}
ldap_args[:host] = "ldap.office.infoxchange.net.au"
ldap_args[:base] = "ou=People,dc=ldap,dc=office,dc=infoxchange,dc=net,dc=au"
ldap_args[:encryption] = :simple_tls
ldap_args[:port] = 636

# Bind anonymously to lookup full dn of username
auth = {}
auth[:method] = :anonymous
ldap_args[:auth] = auth

ldap = Net::LDAP.new(ldap_args)

filter = Net::LDAP::Filter.eq( "objectclass", "person")
treebase = ldap_args[:base]
attrs = ["dn"]

# Get the full dn of the username
userpath = nil
ldap.search(:base => treebase, :filter => filter, :attributes => attrs) do |entry|
  entry.each do |attribute, values|
    if values[0].split(',')[0] == "uid=#{username}"
      userpath = values
    end
  end
end

# Setup an authenticated bind
auth[:username] = userpath
auth[:password] = password
auth[:method] = :simple

ldap_authed = Net::LDAP.new(ldap_args)

# Define operations to be performed
ops = [
  [:replace, :telephoneNumber, ["9452 6401"]], #TODO replace with password when ready
]

# Modify user based on operations
ldap_authed.modify :dn => userpath, :operations => ops

puts "LDAP results:"
puts "Result: #{ldap.get_operation_result.code}"
puts "Message: #{ldap.get_operation_result.message}"