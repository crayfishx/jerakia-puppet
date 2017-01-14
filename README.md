# jerakia-puppet

## Summary

This gem provides the data binding library for Puppet to lookup data over the Jerakia Server REST API using the [Jerakia client](https://github.com/crayfishx/jerakia-client) library

## Installation

```
# /opt/puppetlabs/puppet/bin/gem install puppet-databinding-jerakiaserver
# /opt/puppetlabs/bin/puppetserver gem install puppet-databinding-jerakiaserver
```

## Usage

Edit `puppet.conf` and set the `data_binding_terminus` to `jerakiaserver`

```
[main]
data_binding_terminus = jerakia
```


## License ##

Jerakia libraries are distributed under the Apache 2.0 license



