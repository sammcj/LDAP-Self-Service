require 'rubygems'
require 'net/ldap'
require 'sinatra'
require 'yaml'
require 'thin'

# Use thin as webserver listening on localhost:4567
set :server, "thin"

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

ldap_args = {}

get '/' do
  erb :login_form
end

post '/login/attempt' do

    # Loop through yaml reading configuration
  ldap_config = YAML.load_file 'ldap_servers.yml'
  ldap_config.each_key { |key|

    ldap_args[:host] = ldap_config[key]["host"]
    ldap_args[:base] = ldap_config[key]["base"]
    ldap_args[:encryption] = ldap_config[key]["encryption"].to_sym
    ldap_args[:port] = ldap_config[key]["port"]
    ldap_args[:attrs] = ldap_config[key]["attrs"]
    ldap_args[:type] = ldap_config[key]["type"]

    treebase = ldap_args[:base]
    username = params['username']
    currentpw = params['currentpw']
    newpw = params['newpw']
    newpw2 = params['newpw2']
    userpath = nil

    auth = {}
    auth[:password] = currentpw

    # Define LDAP operations to be performed
    ops = [
      [:replace, :userPassword, [newpw]],
    ]

    # Check the new passwords match
    if newpw != newpw2
      raise "New passwords didn't match!"
    end

    # Retrieve account info for LDAP or AD
    if ldap_args[:type] == 'ldap'
      filter = Net::LDAP::Filter.eq("objectclass", "person")

      #Bind anonymously to lookup full dn of username
      auth[:method] = :anonymous
      ldap_args[:auth] = auth
      ldap = Net::LDAP.new(ldap_args)

      # Get the full dn of the username
      ldap.search(:base => treebase, :filter => filter) do |entry|
        entry.each do |attribute, values|
          if values[0].split(',')[0] == "uid=#{username}"
            userpath = values
          end
        end
      end

      # Setup an authenticated LDAP bind with full DN
      auth[:username] = userpath
      auth[:password] = currentpw
      auth[:method] = :simple

      ldap_authed = Net::LDAP.new(ldap_args)

      # Modify user based on operations
      ldap_authed.modify :dn => userpath, :operations => ops

      # Debug info
      puts "LDAP Result: #{ldap.get_operation_result.code}"
      puts "LDAP Message: #{ldap.get_operation_result.message}"

    elsif ldap_args[:type] == 'ad'

      # Bind to AD
      ad = Net::LDAP.new(
        host: ldap_args[:host],
        auth: { method: :simple, username: username, password: currentpw }
      )

      # Get the full DN of the username
      ad.search(
        base:         treebase,
        filter:       "sAMAccountName=#{username}",
        return_result:true
      ) do |entry |
        userpath = entry.dn
      end

      ad.modify :dn => userpath, :operations => ops

      # Debug info
      puts "AD Result: #{ad.get_operation_result.code}"
      puts "AD Message: #{ad.get_operation_result.message}"

    end
  }

  password_changed = session[:previous_url] || '/passwordchanged'
  redirect to password_changed
end

get '/passwordchanged' do
  erb "Password for user <%=session[:identity]%> has been changed"
end
