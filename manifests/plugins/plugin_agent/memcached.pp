class newrelic::plugins::plugin_agent::memcached (
  $app_name = $::hostname,
  $host     = 'localhost',
  $port     = 11211,
  $path     = undef,
) {
  newrelic::plugins::plugin_agent::memcached::config { 'name': value => $app_name }
  newrelic::plugins::plugin_agent::memcached::config { 'host': value => $host }
  if ($port == '') or ($port == undef) {
    if $path != undef {
      newrelic::plugins::plugin_agent::memcached::config { 'path': value => $path }
    } else {
      fail ("Need to define one: port or path!")
    }
  } else {
    newrelic::plugins::plugin_agent::memcached::config { 'port': value => $port, type => 'integer' }
  }
}

define newrelic::plugins::plugin_agent::memcached::config (
  $value,
  $type = undef,
) {
  yaml_setting { "newrelic_plugin_agent config memcached-${name}" :
    target  => '/etc/newrelic/newrelic_plugin_agent.cfg',
    key     => "Application/memcached/${name}",
    value   => $value,
    type    => $type,
    require => Yaml_setting [ 'newrelic_plugin_agent config license key' ],
    notify  => Service [ 'newrelic_plugin_agent' ],
  }
}