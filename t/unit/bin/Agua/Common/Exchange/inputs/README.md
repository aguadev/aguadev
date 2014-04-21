# Perl code for RabbitMQ tutorials

Here you can find Perl code examples from [RabbitMQ
tutorials](http://www.rabbitmq.com/getstarted.html).

To successfully use the examples you will need a running RabbitMQ server.

## Requirements

To run this code you need to install Net::RabbitFoot.

    cpan -i Net::RabbitFoot

For tutorial six UUID::Tiny needs to be installed.

    cpan -i UUID::Tiny

On Ubuntu:
    
    sudo apt-get install make libclass-data-inheritable-perl libtest-deep-perl libmoosex-app-cmd-perl libcoro-perl libjson-xs-perl libxml-libxml-perl libconfig-any-perl libmoosex-attributehelpers-perl libmoosex-configfromfile-perl libtest-exception-perl libfile-sharedir-perl libreadonly-xs-perl libuuid-tiny-perl
    sudo cpan -i Net::RabbitFoot

## Code

[Tutorial one: "Hello World!"](http://www.rabbitmq.com/tutorial-one-python.html):

    perl send.pl
    perl receive.pl


[Tutorial two: Work Queues](http://www.rabbitmq.com/tutorial-two-python.html):

    perl new_task.pl "A very hard task which takes two seconds.."
    perl worker.pl


[Tutorial three: Publish/Subscribe](http://www.rabbitmq.com/tutorial-three-python.html):

    perl receive_logs.pl
    perl emit_log.pl "info: This is the log message"


[Tutorial four: Routing](http://www.rabbitmq.com/tutorial-four-python.html):

    perl receive_logs_direct.pl info
    perl emit_log_direct.pl info "The message"


[Tutorial five: Topics](http://www.rabbitmq.com/tutorial-five-python.html):

    perl receive_logs_topic.pl "*.rabbit"
    perl emit_log_topic.pl red.rabbit Hello


[Tutorial six: RPC](http://www.rabbitmq.com/tutorial-six-python.html):

    perl rpc_server.pl
    perl rpc_client.pl
