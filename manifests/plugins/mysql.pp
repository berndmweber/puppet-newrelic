class newrelic::plugins::mysql (
  $file_name      = 'newrelic_mysql_plugin-1.0.8.tar.gz',
  $local_filepath = '/usr/local/share',
  $agent_url      = "https://github.com/newrelic-platform/newrelic_mysql_java_plugin/raw/master/dist/",
  $license_key    = $newrelic::server::newrelic_license_key,
  $app_name       = $newrelic::php::newrelic_php_conf_appname,
  $db_password,
  $metrics        = 'status,newrelic',
) {
  $basename = inline_template ( "<%= File.basename('${file_name}', '.tar.gz') %>" )
  $local_dir = "${local_filepath}/${basename}"
  
  class { 'newrelic::plugins::mysql::install' : }
  class { 'newrelic::plugins::mysql::configure' :
    require => Class [ 'newrelic::plugins::mysql::install' ],
  }
  class { 'newrelic::plugins::mysql::service' :
    require => Class [ 'newrelic::plugins::mysql::configure' ],
  }
}

class newrelic::plugins::mysql::install (
  $file_name      = $newrelic::plugins::mysql::file_name,
  $local_filepath = $newrelic::plugins::mysql::local_filepath,
  $agent_url      = $newrelic::plugins::mysql::agent_url,
) {
  # Download mysql source code
  common::configure::download::file { $file_name :
    url                => $agent_url,
    download_provider  => 'wget',
    unpack             => true,
    unpack_destination => $local_filepath,
    require            => Class [ 'common' ],
  }
}

class newrelic::plugins::mysql::configure (
  $local_filepath = $newrelic::plugins::mysql::local_dir,
  $license_key    = $newrelic::server::newrelic_license_key,
  $app_name       = $newrelic::php::newrelic_php_conf_appname,
  $db_password    = $newrelic::plugins::mysql::db_password,
  $metrics        = $newrelic::plugins::mysql::metrics,
) {
  #configure plugin
  file { "${local_filepath}/config/newrelic.properties" :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template ( "newrelic/plugins/newrelic_mysql_plugin.properties.erb" ),
  }
  file { "${local_filepath}/config/mysql.instance.json" :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template ( "newrelic/plugins/newrelic_mysql_plugin.instance.json.erb" ),
    require => File [ "${local_filepath}/config/newrelic.properties" ],
  }
  file { "${local_filepath}/config/logging.properties" :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template ( "newrelic/plugins/newrelic_mysql_plugin_logging.properties.erb" ),
    require => File [ "${local_filepath}/config/mysql.instance.json" ],
  }

  # Configure MySQL
  mysql_user { 'newrelic@localhost' :
    ensure        => 'present',
    password_hash => mysql_password($db_password),
  }
  mysql_user { 'newrelic@127.0.0.1' :
    ensure        => 'present',
    password_hash => mysql_password($db_password),
  }
  mysql_grant { 'newrelic@localhost/*.*' :
    options    => [ 'GRANT' ],
    privileges => [ 'PROCESS', 'REPLICATION CLIENT' ],
    table      => '*.*',
    user       => 'newrelic@localhost',
    require    => Mysql_user[ 'newrelic@localhost' ],
  }
  mysql_grant { 'newrelic@127.0.0.1/*.*' :
    options    => [ 'GRANT' ],
    privileges => [ 'PROCESS', 'REPLICATION CLIENT' ],
    table      => '*.*',
    user       => 'newrelic@127.0.0.1',
    require    => Mysql_user[ 'newrelic@127.0.0.1' ],
  }

  # Configure daemon
  file { '/etc/init.d/newrelic_mysql_plugin' :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template ( "newrelic/plugins/newrelic_mysql_plugin.init.erb" ),
    require => [
      Mysql_grant [ 'newrelic@localhost/*.*', 'newrelic@127.0.0.1/*.*' ],
      File [ "${local_filepath}/config/logging.properties" ],
    ],
  }
}

class newrelic::plugins::mysql::service (
  $local_filepath = $newrelic::plugins::mysql::local_dir,
) {
  service { 'newrelic_mysql_plugin' :
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File [
      '/etc/init.d/newrelic_mysql_plugin',
      "${local_filepath}/config/newrelic.properties",
      "${local_filepath}/config/mysql.instance.json"
    ],
  }
}
