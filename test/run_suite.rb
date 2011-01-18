# Loading the Cocoa framework. If you need to load more frameworks, you can do that here too.
framework 'Cocoa'

require 'rexml/document'
require 'fileutils'
require 'erb'
require 'tempfile'
require 'cgi'

Dir.glob(File.expand_path('../../src/*.rb', __FILE__)).each { |klass| require klass }
Dir.glob(File.expand_path('../**/*_test.rb', __FILE__)).each { |test| require test }
