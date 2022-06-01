# just a sample module to show some stuff
class ec2mongodb {

  $packages       = ['python-pip','net-tools','ntp']
  $mongo_array    = lookup('mongodb::hosts')
  $mongo_backup   = lookup('mongodb::backup')
  $dbpath         = '/data/db/mongodb'

  package { $packages:
    ensure => installed,
  }

  include sysctl::base
  sysctl { 'net.core.busy_read': value => '50', }
  sysctl { 'net.core.busy_poll': value => '50', }
  sysctl { 'net.core.somaxconn': value => '4096', }
  sysctl { 'net.ipv4.tcp_fastopen': value => '3', }
  sysctl { 'net.ipv4.tcp_fin_timeout': value => '30', }
  sysctl { 'net.ipv4.tcp_keepalive_intvl': value => '30', }
  sysctl { 'net.ipv4.tcp_keepalive_time': value => '120', }
  sysctl { 'net.ipv4.tcp_max_syn_backlog': value => '4096', }
  sysctl { 'kernel.numa_balancing': value => '0', }
  sysctl { 'vm.swappiness': value => '0', }
  sysctl { 'vm.zone_reclaim_mode': value => '0', }

  file { '/data':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/data/db':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/data/db/bin':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/data/db/backup':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/logrotate.d/mongodb':
    content => template("${module_name}/etc/logrotate.d/mongodb.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 'u=rw,go=r',
  }

  class { '::mongodb::globals':
    manage_package_repo => true,
    version             => '5.0.6',
  } ->
  class { '::mongodb::client': } ->
  class { '::mongodb::server':
    ensure         => present,
    restart        => false,
    auth           => true,
    replset        => "${replicaset}",
    replset_config => {
      "${replicaset}" => {
        ensure  => present,
        members => $mongo_array
      }
    },
    create_admin   => true,
    admin_username => 'admin',
    admin_password => "${adminpw}",
    admin_roles    => ['root'],
    dbpath         => $dbpath,
    storage_engine => 'wiredTiger',
    bind_ip        => ['0.0.0.0'],
    store_creds    => true,
    keyfile        => '/etc/mongo-key',
    key            => "${cluster_key}",
  } ->
  file { '/var/log/mongodb/mongod.log':
    ensure => file,
    owner  => 'mongodb',
    group  => 'mongodb',
    mode   => '0644',
  } ->
  mongodb::db {
    'demo':
      user          => 'demo',
      password_hash => mongodb_password('demo', "${demopw}"),
      roles         => ['readWrite'];
  } ->
  file_line { "change pid path":
    path   => '/etc/mongod.conf',
    line   => '  pidFilePath: /var/run/mongodb/mongod.pid',
    replace => true,
    match  => 'pidFilePath',
  } ->
  file_line { "add pid dir":
    path    => '/lib/systemd/system/mongod.service',
    line    => 'ExecStartPre=/bin/mkdir -p /var/run/mongodb ; /bin/chown mongodb:mongodb /var/run/mongodb ; /bin/chmod 0755 /var/run/mongodb',
    after   => 'ExecStart',
  } ->
  file_line { "add PermissionsStartOnly=true":
    path    => '/lib/systemd/system/mongod.service',
    line    => 'PermissionsStartOnly=true',
    after   => 'ExecStartPre',
  } ->
  package { 'mongodb-org-tools': ensure => installed, }
  package { 'mongodb-mongosh': ensure => installed, }

  mongodb_user { monitoring:
    name          => 'monitoring',
    ensure        => present,
    password_hash => mongodb_password('monitoring', 'YbPM6LWs31VoIKn'),
    database      => admin,
    roles         => ['clusterMonitor'],
    tries         => 10,
    require       => Class['mongodb::server'],
  }

  exec { "disable_transparent_hugepage_enabled":
    command => "/bin/echo never > /sys/kernel/mm/transparent_hugepage/enabled",
    unless  => "/bin/grep -c '[never]' /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null",
  }

  exec { "disable_transparent_hugepage_defrag":
    command => "/bin/echo never > /sys/kernel/mm/transparent_hugepage/defrag",
    unless  => "/bin/grep -c '[never]' /sys/kernel/mm/transparent_hugepage/defrag 2>/dev/null",
  }

  package { 'pymongo':
    ensure   => installed,
    provider => 'pip',
  }

  if $mongo_backup {
    cron { 'mongodb-backup':
      ensure  => 'present',
      command => '/data/db/bin/mongodb-backup.sh >/dev/null 2>&1',
      hour    => ['2'],
      minute  => '0',
      target  => 'root',
      user    => 'root',
    }
  }
  else {
    cron { 'mongodb-backup':
      ensure  => 'absent',
      user    => 'root',
    }
  }

  file { '/data/db/bin/mongodb-backup.sh':
    content => template("${module_name}/data/db/bin/mongodb-backup.sh.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }

}
