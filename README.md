LDAP Self Service
====

A small web based LDAP self-service portal


### Requirements

* sinatra
* net-ldap
* thin

Tested with Ruby 2.1.1

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

```
bundle install
thin install
cp thin.yml /etc/thin/ldapss.yml
/etc/init.d/thin start
```

ruby app.rb

Note: Designed to have nginx with SSL proxying back to the app on localhost:4567

### Screenshot

![screenshot](https://cloud.githubusercontent.com/assets/862951/4314679/666fcfec-3ee4-11e4-825f-03dc2a6b1f6f.png)
