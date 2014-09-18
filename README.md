LDAP Self Service
====

A small web based LDAP self-service portal

### Configuration

Enter your ldap settings in ldap.yml

The required settings are:

```
host: your.ldap.server.com
base: ou=People,dc=ldap,dc=server,dc=com
port: 636
encryption: simple_tls
attrs: dn
```

### Install

Run bundle install
ruby app.rb

Note: Designed to have nginx with SSL proxying back to the app on localhost:4567
