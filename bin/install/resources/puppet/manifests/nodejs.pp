Exec {
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin",
}

include nodejs

#class install {
#    class {
#        nodejs:;
#    }
#}
#
#include install
#

package { 'npm':
    ensure  =>  installed,
}

package { 'express':
    provider => 'npm',
}

package { 'rabbit.js':
    provider => 'npm',
}

package { 'forever':
    provider => 'npm',
}
