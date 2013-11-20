class newrelic::plugins::nginx (
  $file_name      = "newrelic_nginx_agent.tar.gz",
  $local_filepath = "/usr/local/share",
  $agent_url      = "http://nginx.com/download/newrelic/",
  $license_key    = $newrelic::server::newrelic_license_key,
  $app_name       = $newrelic::php::newrelic_php_conf_appname,
) {
  $local_dir = "${local_filepath}/newrelic_nginx_agent"
  
  class { 'newrelic::plugins::nginx::install' : }
  class { 'newrelic::plugins::nginx::configure' :
    require => Class [ 'newrelic::plugins::nginx::install' ],
  }
  class { 'newrelic::plugins::nginx::service' :
    require => Class [ 'newrelic::plugins::nginx::configure' ],
  }
}

class newrelic::plugins::nginx::install (
  $file_name      = $newrelic::plugins::nginx::file_name,
  $local_filepath = $newrelic::plugins::nginx::local_filepath,
  $agent_url      = $newrelic::plugins::nginx::agent_url,
) {
  # Download nginx source code
  common::configure::download::file { $file_name :
    url                => $agent_url,
    unpack             => true,
    unpack_destination => $local_filepath,
    require            => Class [ 'common' ],
  }
}

class newrelic::plugins::nginx::configure (
  $local_filepath = "/usr/local/share",
  $license_key    = $newrelic::server::newrelic_license_key,
  $app_name       = $newrelic::php::newrelic_php_conf_appname,
) {
  #configure plugin
  file { "${newrelic::plugins::nginx::local_dir}/config/newrelic_plugin.yml" :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template ( "newrelic/plugins/newrelic_nginx_plugin.yml.erb" ),
  }
  
  #configure daemon
  file { '/etc/init.d/newrelic_nginx_agent' :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template ( "newrelic/plugins/newrelic_nginx_agent.daemon.erb" ),
  }

  #run newrelic-nginx-agent-bundler
  ruby::bundle::install { 'newrelic-nginx-agent-bundler' :
    path    => $newrelic::plugins::nginx::local_dir,
    creates => "${newrelic::plugins::nginx::local_dir}/Gemfile.lock",
  }
}

class newrelic::plugins::nginx::service (
  $file_name      = "newrelic_nginx_agent.tar.gz",
  $local_filepath = "/usr/local/share",
  $agent_url      = "http://nginx.com/download/newrelic/",
  $license_key    = $newrelic::server::newrelic_license_key,
  $app_name       = $newrelic::php::newrelic_php_conf_appname,
) {
  service { 'newrelic_nginx_agent' :
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File [
      '/etc/init.d/newrelic_nginx_agent',
      "${newrelic::plugins::nginx::local_dir}/config/newrelic_plugin.yml"
    ],
  }
}
