LDAP Self Service
====

A small web based LDAP self-service portal

[![Code Climate](https://codeclimate.com/github/sammcj/LDAP-Self-Service/badges/gpa.svg)](https://codeclimate.com/github/sammcj/LDAP-Self-Service)

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
ln -s thin.yml /etc/thin/ldapss.yml
/etc/init.d/thin start
```

Note: You may start the application interactively by running:
```ruby app.rb```

Note: Designed to have nginx with SSL proxying back to the app on localhost:4567

### Screenshot

![screenshot](https://cloud.githubusercontent.com/assets/862951/4314679/666fcfec-3ee4-11e4-825f-03dc2a6b1f6f.png)

### Puppet

You can deploy with puppet with *something* kind of like this:

```
  vcsrepo { '/var/vhost/selfservice':
    ensure   => latest,
    provider => git,
    source   => 'git@gitlab.yourcompany.com:ldap-self-service.git',
    require  => File['/var/vhost'],
    notify   => Exec['ldap-bundle']
  }

  exec { 'ldap-bundle':
    command     => 'cd /var/vhost/selfservice && bundle install',
    refreshonly => true,
    notify      => Exec['thin-install'],
  }

  exec { 'thin-install':
    command     => 'cd /var/vhost/selfservice && thin install',
    refreshonly => true,
  }

  file { '/etc/thin/ldapss.yml':
    ensure => link,
    target => '/var/vhost/selfservice/thin.yml'
  }

  service { 'thin':
    enable      => true,
    ensure      => running,
    hasrestart  => true,
    hasstatus   => true,
    require     => File['/etc/thin/ldapss.yml'],
  }

  ixanginx::reverseproxy { 'selfservice.yourcompany.com':
    proxy_passthrough  => 'http://localhost:4567',
    ssl                => true,
    crt_name           => 'wildcard.yourcompany.com.crt',
    key_name           => 'wildcard.yourcompany.com.key',
  }
```
