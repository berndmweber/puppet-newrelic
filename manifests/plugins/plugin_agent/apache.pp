class newrelic::plugins::plugin_agent::apache (
  $app_name         = $::hostname,
  $scheme           = 'http',
  $host             = 'localhost',
  $verify_ssl_cert  = 'false',
  $port             = '80',
  $path             = '/server-status',
) {
  newrelic::plugins::plugin_agent::apache::config { 'name': value => $app_name }
  newrelic::plugins::plugin_agent::apache::config { 'scheme': value => $scheme }
  newrelic::plugins::plugin_agent::apache::config { 'host': value => $host }
  newrelic::plugins::plugin_agent::apache::config { 'verify_ssl_cert': value => $verify_ssl_cert }
  newrelic::plugins::plugin_agent::apache::config { 'port': value => $port, type => 'integer' }
  newrelic::plugins::plugin_agent::apache::config { 'path': value => $path }
}

define newrelic::plugins::plugin_agent::apache::config (
  $value,
  $type = undef,
) {
  yaml_setting { "newrelic_plugin_agent config apache_httpd-${name}" :
    target  => '/etc/newrelic/newrelic_plugin_agent.cfg',
    key     => "Application/apache_httpd/${name}",
    value   => $value,
    type    => $type,
    require => Yaml_setting [ 'newrelic_plugin_agent config license key' ],
    notify  => Service [ 'newrelic_plugin_agent' ],
  }
}