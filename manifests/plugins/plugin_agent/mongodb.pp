class newrelic::plugins::plugin_agent::mongodb (
  $app_name       = $::hostname,
  $host           = 'localhost',
  $port           = 27017,
  $admin_username = undef,
  $admin_password = undef,
  $ssl            = undef,
  $ssl_keyfile    = undef,
  $ssl_certfile   = undef,
  $ssl_cert_reqs  = undef,
  $ssl_ca_certs   = undef,
  $databases,
) {
  newrelic::plugins::plugin_agent::mongodb::config { 'name': value => $app_name }
  newrelic::plugins::plugin_agent::mongodb::config { 'host': value => $host }
  newrelic::plugins::plugin_agent::mongodb::config { 'port': value => $port, type => 'integer' }
  if $admin_username != undef {
    newrelic::plugins::plugin_agent::mongodb::config { 'admin_username': value => $admin_username }
  }
  if $admin_password != undef {
    newrelic::plugins::plugin_agent::mongodb::config { 'admin_password': value => $admin_password }
  }
  if $ssl != undef {
    newrelic::plugins::plugin_agent::mongodb::config { 'ssl': value => $ssl }
  }
  if $ssl_keyfile != undef {
    newrelic::plugins::plugin_agent::mongodb::config { 'ssl_keyfile': value => $ssl_keyfile }
  }
  if $ssl_certfile != undef {
    newrelic::plugins::plugin_agent::mongodb::config { 'ssl_certfile': value => $ssl_certfile }
  }
  if $ssl_cert_reqs != undef {
    newrelic::plugins::plugin_agent::mongodb::config { 'ssl_cert_reqs': value => $ssl_cert_reqs }
  }
  if $ssl_ca_certs != undef {
    newrelic::plugins::plugin_agent::mongodb::config { 'ssl_ca_certs': value => $ssl_ca_certs }
  }
  newrelic::plugins::plugin_agent::mongodb::config { 'databases': value => $databases, type => 'array' }
}

define newrelic::plugins::plugin_agent::mongodb::config (
  $value,
  $type = undef,
) {
  yaml_setting { "newrelic_plugin_agent config mongodb-${name}" :
    target  => '/etc/newrelic/newrelic_plugin_agent.cfg',
    key     => "Application/mongodb/${name}",
    value   => $value,
    type    => $type,
    require => Yaml_setting [ 'newrelic_plugin_agent config license key' ],
    notify  => Service [ 'newrelic_plugin_agent' ],
  }
}