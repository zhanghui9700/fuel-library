class cobbler::server {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  case $operatingsystem {
    /(?i)(centos|redhat)/:  {

      $cobbler_service = "cobblerd"
      $cobbler_web_service = "httpd"
      $dnsmasq_service = "dnsmasq"

      service { "xinetd":
        enable => true,
        ensure => running,
        hasrestart => true,
        require => Package[$cobbler::packages::cobbler_additional_packages],
      }

      file { "/etc/xinetd.conf":
        content => template("cobbler/xinetd.conf.erb"),
        owner => root,
        group => root,
        mode => 0600,
        require => Package[$cobbler::packages::cobbler_additional_packages],
        notify => Service["xinetd"],
      }

    }
    /(?i)(debian|ubuntu)/:  {

      $cobbler_service = "cobbler"
      $cobbler_web_service = "apache2"
      $dnsmasq_service = "dnsmasq"
      $apache_ssl_module = "ssl"

    }
  }

  Service[$cobbler_service] -> Exec["cobbler_sync"] -> Service[$dnsmasq_service]

  service { $cobbler_service:
    enable => true,
    ensure => running,
    hasrestart => true,
    require => Package[$cobbler::packages::cobbler_package],
  }

  service { $dnsmasq_service:
    enable => true,
    ensure => running,
    hasrestart => true,
    require => Package[$cobbler::packages::dnsmasq_package],
    subscribe => Exec["cobbler_sync"],
  }

  if $apache_ssl_module {
    exec {'ssl':
      command => "/usr/sbin/a2enmod ssl",
      before  => Service[$cobbler_web_service],
      notify  => Service[$cobbler_web_service],
    }
  }

  service { $cobbler_web_service:
    enable => true,
    ensure => running,
    hasrestart => true,
    require => Package[$cobbler::packages::cobbler_web_package],
  }

  exec {"cobbler_sync":
    command => "sleep 3 && cobbler sync > /tmp/cobbler_sync.log 2>&1",
    refreshonly => true,
    returns => [0, 155],
    require => [
                Package[$cobbler::packages::cobbler_package],
                Package[$cobbler::packages::dnsmasq_package],
                ],
    subscribe => Service[$cobbler_service],
    notify => Service[$dnsmasq_service],
  }

  file { "/etc/cobbler/modules.conf":
    content => template("cobbler/modules.conf.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => [
                Package[$cobbler::packages::cobbler_package],
                ],
    notify => [
               Service[$cobbler_service],
               Exec["cobbler_sync"],
               ],
  }

  file {"/etc/cobbler/settings":
    content => template("cobbler/settings.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => Package[$cobbler::packages::cobbler_package],
    notify => [
               Service[$cobbler_service],
               Exec["cobbler_sync"],
               ],
  }

  file {"/etc/cobbler/dnsmasq.template":
    content => template("cobbler/dnsmasq.template.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => [
                Package[$cobbler::packages::cobbler_package],
                Package[$cobbler::packages::dnsmasq_package],
                ],
    notify => [
               Service[$cobbler_service],
               Exec["cobbler_sync"],
               Service[$dnsmasq_service],
               ],
  }


  file {"/etc/cobbler/pxe/pxedefault.template":
    content => template("cobbler/pxedefault.template.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => Package[$cobbler::packages::cobbler_package],
    notify => [
               Service[$cobbler_service],
               Exec["cobbler_sync"],
               ],
  }

  }
