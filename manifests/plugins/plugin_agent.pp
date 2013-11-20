class newrelic::plugins::plugin_agent (
  $package_name     = 'newrelic-plugin-agent',
  $local_filepath   = "/opt/newrelic_plugin_agent",
  $license_key      = $newrelic::server::newrelic_license_key,
  $app_name         = $newrelic::php::newrelic_php_conf_appname,
  $enable_apache    = false,
  $enable_memcached = false,
  $enable_mongodb   = false,
  $enable_uwsgi     = false,
) {
  $local_dir = $local_filepath
  
  class { 'newrelic::plugins::plugin_agent::install' : }
  class { 'newrelic::plugins::plugin_agent::configure' :
    require => Class [ 'newrelic::plugins::plugin_agent::install' ],
  }
  if $enable_apache == true {
    class { 'newrelic::plugins::plugin_agent::apache' : }
  }
  if $enable_memcached == true {
    class { 'newrelic::plugins::plugin_agent::memcached' : }
  }
  if $enable_mongodb == true {
    class { 'newrelic::plugins::plugin_agent::mongodb' :
      require => Package [ 'pymongo' ],
    }
  }
  if $enable_uwsgi == true {
    class { 'newrelic::plugins::plugin_agent::uwsgi' : }
  }
  class { 'newrelic::plugins::plugin_agent::service' :
    require => Class [ 'newrelic::plugins::plugin_agent::configure' ],
  }
}

class newrelic::plugins::plugin_agent::install (
  $package_name   = $newrelic::plugins::plugin_agent::package_name,
  $local_filepath = $newrelic::plugins::plugin_agent::local_filepath,
) {
  # Download plugin_agent
  package { $package_name :
    ensure    => present,
    provider  => 'pip',
    require   => Package [ 'python-pip' ],
  }
}

class newrelic::plugins::plugin_agent::configure (
  $package_name   = $newrelic::plugins::plugin_agent::package_name,
  $local_filepath = $newrelic::plugins::plugin_agent::local_filepath,
  $license_key    = $newrelic::server::newrelic_license_key,
  $app_name       = $newrelic::php::newrelic_php_conf_appname,
) {
  file { '/var/log/newrelic/newrelic_plugin_agent.log' :
    owner   => 'newrelic',
    group   => 'root',
    require => File [ '/var/log/newrelic' ],
  }

  #configure plugin
  file { '/etc/newrelic/newrelic_plugin_agent.cfg' :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    replace => false,
    source  => '/opt/newrelic_plugin_agent/newrelic_plugin_agent.cfg',
  }
  exec { 'correct-yaml-format' :
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'sed -i -e "/%YAML 1\.2/d" /etc/newrelic/newrelic_plugin_agent.cfg',
    onlyif  => 'grep "%YAML 1\.2" /etc/newrelic/newrelic_plugin_agent.cfg',
    require => File [ '/etc/newrelic/newrelic_plugin_agent.cfg' ],
  }
  yaml_setting { 'newrelic_plugin_agent config license key' :
    target  => '/etc/newrelic/newrelic_plugin_agent.cfg',
    key     => 'Application/license_key',
    value   => $license_key,
    require => Exec [ 'correct-yaml-format' ],
  }

  # Configure daemon
  file { '/etc/init.d/newrelic_plugin_agent' :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => '/opt/newrelic_plugin_agent/newrelic_plugin_agent.deb',
    require => Yaml_setting [ 'newrelic_plugin_agent config license key' ],
  }
}

class newrelic::plugins::plugin_agent::service (
) {
  service { 'newrelic_plugin_agent' :
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File [
      '/etc/init.d/newrelic_plugin_agent',
      "/etc/newrelic/newrelic_plugin_agent.cfg"
    ],
    require    => File [ '/var/log/newrelic/newrelic_plugin_agent.log' ],
  }
}
