#!/bin/bash
sudo pear channel-discover pear.phpunit.de
sudo pear channel-discover pear.symfony-project.com
sudo pear channel-discover components.ez.no
sudo pear update-channels
sudo pear upgrade-all
sudo pear install --alldeps phpunit/PHPUnit
sudo apt-get install phpunit

sudo pear uninstall phpunit/PHPUnit
sudo pear install phpunit/PHPUnit