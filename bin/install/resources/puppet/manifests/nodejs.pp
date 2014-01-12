Exec {
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin",
}

class install {
    class {
        nodejs:;
    }
}

include install

package { 'express':
    provider => 'npm',
}

package { 'rabbit.js':
    provider => 'npm',
}

package { 'forever':
    provider => 'npm',
}
