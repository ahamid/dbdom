#!/bin/sh

jruby -w -J-cp /usr/share/derby/lib/derby.jar:lib/xercesImpl-2.9.1.jar -Ilib test/dbdom_test.rb
#jruby -w -J-cp /usr/share/derby/lib/derby.jar advice_test.rb
