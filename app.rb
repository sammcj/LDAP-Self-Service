require 'rubygems'
require 'net/ldap'
require 'sinatra'
require 'yaml'
require 'thin'

# Use thin as webserver listening on localhost:4567
set :server, "thin"

# Read configuration
config=YAML.load_file('ldap.yml')
ldap_args = {}
ldap_args[:host] = config["host"]
ldap_args[:base] = config["base"]
ldap_args[:encryption] = config["encryption"].to_sym
ldap_args[:port] = config["port"]

filter = Net::LDAP::Filter.eq( "objectclass", "person")
treebase = ldap_args[:base]
attrs = ldap_args["dn"]

# Handle errors
set :show_exceptions, false

error do
  'Ruh, Roh there was a nasty error - ' + env['sinatra.error'].to_s
end

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'LDAP Self Service Portal'
  end
end

get '/' do
  erb :login_form
end

post '/login/attempt' do
  username = params['username']
  currentpw = params['currentpw']

  # Check the new passwords match
  newpw = params['newpw']
  newpw2 = params['newpw2']

  if newpw != newpw2
    raise "New passwords didn't match!"
  end

  #Bind anonymously to lookup full dn of username
  auth = {}
  auth[:method] = :anonymous
  ldap_args[:auth] = auth

  ldap = Net::LDAP.new(ldap_args)

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
  auth[:password] = currentpw
  auth[:method] = :simple

  ldap_authed = Net::LDAP.new(ldap_args)

  # Define operations to be performed
  ops = [
    [:replace, :telephoneNumber, [newpw]], #TODO replace with password when ready
  ]

  # Modify user based on operations
  ldap_authed.modify :dn => userpath, :operations => ops
  password_changed = session[:previous_url] || '/passwordchanged'

  redirect to password_changed
end

get '/passwordchanged' do
  erb "Password for user <%=session[:identity]%> has been changed"
end
