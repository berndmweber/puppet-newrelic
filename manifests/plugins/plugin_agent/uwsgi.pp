class newrelic::plugins::plugin_agent::uwsgi (
  $app_name = $::hostname,
  $host     = 'localhost',
  $port     = 1717,
  $path     = undef,
) {
  newrelic::plugins::plugin_agent::uwsgi::config { 'host': value   => $host }
  newrelic::plugins::plugin_agent::uwsgi::config { 'name':
    value   => $app_name,
    require => Newrelic::Plugins::Plugin_agent::Uwsgi::Config  [ 'host' ],
  }
  if ($port == '') or ($port == undef) {
    if $path != undef {
      newrelic::plugins::plugin_agent::uwsgi::config { 'path':
        value   => $path,
        require => Newrelic::Plugins::Plugin_agent::Uwsgi::Config  [ 'name' ],
      }
    } else {
      fail ("Need to define one: port or path!")
    }
  } else {
    newrelic::plugins::plugin_agent::uwsgi::config { 'port':
      value   => $port,
      type    => 'integer',
      require => Newrelic::Plugins::Plugin_agent::Uwsgi::Config  [ 'name' ],
    }
  }
}

define newrelic::plugins::plugin_agent::uwsgi::config (
  $value,
  $type = undef,
) {
  yaml_setting { "newrelic_plugin_agent config uwsgi-${name}" :
    target  => '/etc/newrelic/newrelic_plugin_agent.cfg',
    key     => "Application/uwsgi/${name}",
    value   => $value,
    type    => $type,
    require => Yaml_setting [ 'newrelic_plugin_agent config license key' ],
    notify  => Service [ 'newrelic_plugin_agent' ],
  }
}