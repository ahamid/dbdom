#!/bin/sh

# the xerces impl requires the xerces jar
# although the dependency interfaces should already
# be in the JDK

jruby -S gem install maven_gem
jruby -S gem maven xml-apis xml-apis 1.3.04
jruby -S gem maven xml-resolver xml-resolver 1.2
jruby -S gem maven xerces xercesImpl 2.9.1
