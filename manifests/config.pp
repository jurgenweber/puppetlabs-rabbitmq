#
class rabbitmq::config {

  $cluster_disk_nodes       = $rabbitmq::cluster_disk_nodes
  $cluster_node_type        = $rabbitmq::cluster_node_type
  $cluster_nodes            = $rabbitmq::cluster_nodes
  $config                   = $rabbitmq::config
  $config_cluster           = $rabbitmq::config_cluster
  $config_path              = $rabbitmq::config_path
  $config_mirrored_queues   = $rabbitmq::config_mirrored_queues
  $config_stomp             = $rabbitmq::config_stomp
  $env_config               = $rabbitmq::env_config
  $env_config_path          = $rabbitmq::env_config_path
  $erlang_cookie            = $rabbitmq::erlang_cookie
  $node_ip_address          = $rabbitmq::node_ip_address
  $plugin_dir               = $rabbitmq::plugin_dir
  $port                     = $rabbitmq::port
  $service_name             = $rabbitmq::service_name
  $stomp_port               = $rabbitmq::stomp_port
  $wipe_db_on_cookie_change = $rabbitmq::wipe_db_on_cookie_change

  # Handle deprecated option.
  if $cluster_disk_nodes != [] {
    notify { 'cluster_disk_nodes':
      message => 'WARNING: The cluster_disk_nodes is deprecated.
       Use cluster_nodes instead.',
    }
    $_cluster_nodes = $cluster_disk_nodes
  } else {
    $_cluster_nodes = $cluster_nodes
  }

  file { '/etc/rabbitmq':
    ensure  => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
  }

  file { 'rabbitmq.config':
    ensure  => file,
    path    => $config_path,
    content => template($config),
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }

  file { 'rabbitmq-env.config':
    ensure  => file,
    path    => $env_config_path,
    content => template($env_config),
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Class['rabbitmq::service'],
  }


  if $config_cluster {

      # Safety check.
      if $wipe_db_on_cookie_change {
      exec { 'wipe_db':
        command => '/etc/init.d/rabbitmq-server stop; /bin/rm -rf /var/lib/rabbitmq/mnesia',
        require => Package[$package_name],
        unless  => "/bin/grep -qx ${erlang_cookie} /var/lib/rabbitmq/.erlang.cookie"
      }
    } else {
      exec { 'wipe_db':
        command => '/bin/false "ERROR: The current erlang cookie needs to change to ${erlang_cookie}. In order to do this the RabbitMQ database needs to be wiped.  Please set the parameter called wipe_db_on_cookie_change to true to allow this to happen automatically."',
        require => Package[$package_name],
        unless  => "/bin/grep -qx ${erlang_cookie} /var/lib/rabbitmq/.erlang.cookie"
      }
    }

    file { 'erlang_cookie':
      ensure  => 'present',
      path    => '/var/lib/rabbitmq/.erlang.cookie',
      owner   => 'rabbitmq',
      group   => 'rabbitmq',
      mode    => '0400',
      content => $erlang_cookie,
      replace => true,
      before  => File['rabbitmq.config'],
      require => Exec['wipe_db'],
      notify  => Class['rabbitmq::service'],
    }
  }


}
