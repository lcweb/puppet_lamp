# Set default path for Exec calls
Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]
}

class params {
    # Hostname of the virtualbox (make sure this URL points to 127.0.0.1 on your local dev system!)
    $host = 'www.project.dev'

    # Original port (don't change)
    $port = '80'

    # Database names (must match your app/config/parameters.ini file)
    $dbname = 'project'
    $dbtest = 'test'
    $dbuser = 'project'
    $dbpass = 'secret'


    $phpmyadmin = true
}

class sql {
    include mysql

    exec { 'create-db':
        unless => "/usr/bin/mysql -u${params::dbuser} -p${params::dbpass} ${params::dbname}",
        command => "/usr/bin/mysql -e \"create database ${params::dbname}; grant all on ${params::dbname}.* to ${params::dbuser}@localhost identified by '${params::dbpass}';\"",
        require => Service["mysql"],
    }

    exec { 'create-db-test':
        unless => "/usr/bin/mysql -u${params::dbuser} -p${params::dbpass} ${params::dbtest}",
        command => "/usr/bin/mysql -e \"create database ${params::dbtest}; grant all on ${params::dbtest}.* to ${params::dbuser}@localhost identified by '${params::dbpass}';\"",
        require => Service["mysql"],
    }    

}



class ubuntu_repository_update($stage = 'first') {
    
    exec { "apt-update":
        command     => "/usr/bin/apt-get update",
        #refreshonly => true;
    }

    /*file { "/etc/apt/sources.list.d/php5-ppa.list": 
      ensure => present,
      content => template("my_conf_files/php5-ppa.list") 
    }  

    exec { "apt-key":
      command => "wget http://www.dotdeb.org/dotdeb.gpg && cat dotdeb.gpg | sudo apt-key add -
",
    }

    exec { "/usr/bin/apt-get update":
      require => [File["/etc/apt/sources.list.d/php5-ppa.list"], Exec["apt-key"]]
    }*/

}


class web {

    include apache

    file { "/etc/apache2/sites-enabled/000-default": 
      ensure => absent,
      notify => Service['apache']
    }

    # Configure apache virtual host
    apache::vhost { $params::host :
        docroot   => "/vagrant/web",
        template  => "my_conf_files/vhost.conf.erb",
        port      => $params::port,
    }

    # enable mod_rewrite
    exec { "a2enmod rewrite":
      notify => Service['apache'],
      require => Package['apache']
    }


    class { 'php': 
      #version => '5.3.15-1~dotdeb.0'
    }

    php::module { "mysql" : }
    php::module { "gd" : }
    php::module { "sqlite" : }
    php::module { "xdebug" : }

   
    file { "/etc/php5/apache2/conf.d/myconf.ini": 
      ensure => present,
      content => template("my_conf_files/myphp.ini"),
      require => Package['php'],
      notify => Service['apache']
    }   



    # Install PHPMyAdmin on /phpmyadmin
    package { "phpMyAdmin" :
        ensure  => present,
    }

    # Setup our own phpmyadmin configuration file
    file { "/etc/apache2/conf.d/phpMyAdmin.conf" :
        #source  => "puppet:///modules/project/phpmyadmin.conf",
        content => template("my_conf_files/phpmyadmin.conf"),
        owner   => "root",
        group   => "root",
        require => Package["phpMyAdmin"],
        notify  => Service["apache"],
    }    
  
}



class mail {
  class { 'postfix': }
}



node default {
  stage { 'first': before => Stage['main'] }

  include params
  class { 'ubuntu_repository_update': 
      stage => first;
  }
  include sql
  include web
  include mail
}



