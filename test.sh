#!/bin/sh

jruby -w -J-cp /usr/share/derby/lib/derby.jar -Ilib test/dbdom_test.rb
jruby -w -Ilib test/advice_test.rb
