# Loading the Cocoa framework. If you need to load more frameworks, you can do that here too.
framework 'Cocoa'

Dir.glob(File.expand_path('../../Classes/*.rb', __FILE__)).each { |klass| require klass }
Dir.glob(File.expand_path('../**/*_test.rb', __FILE__)).each { |test| require test }
