require 'ftools'

#Creates a project for a robot.  Args are:
# => robot_name (required)
# => image_url=http://imageurl.com/ (optional)
# => profile_url=http://profileurl.com/ (optional)
# e.g. rave my_robot image_url=http://appropriate-casey.appspot.com/image.png profile_url=http://appropriate-casey.appspot.com/profile.json
def create_robot(args)
  robot_name = args.first
  module_name = robot_name.split(/_|-/).collect { |word| word[0, 1].upcase + word[1, word.length-1] }.join("")
  robot_class_name = "#{module_name}::Robot"
  options = { :name => robot_name, :version => 1 }
  args[1, args.length-1].each do |arg|
    key, value = arg.split("=").collect { |part| part.strip }
    options[key.to_sym] = value
  end
  dir = File.join(".", robot_name)
  lib = File.join(dir, "lib")
  config_dir = File.join(dir, "config")
  file = File.join(dir, "robot.rb")
  appengine_web = File.join(dir, "appengine-web.xml")
  config = File.join(dir, "config.ru")
  public_folder = File.join(dir, "public")
  here = File.dirname(__FILE__)
  jar_dir = File.join(here, "..", "jars")
  jars = %w( appengine-api-1.0-sdk-1.2.1.jar jruby-core.jar ruby-stdlib.jar )
  #Create the project dir
  puts "Creating directory #{File.expand_path(dir)}"
  Dir.mkdir(dir)
  puts "Creating robot class #{File.expand_path(file)}"
  #Make the base robot class
  File.open(file, "w") do |f|
    f.puts robot_file_contents(robot_name, module_name)
  end
  #Make the rackup config file
  puts "Creating rackup config file #{File.expand_path(config)}"
  options_str = options.collect { |key, val| ":#{key} => \"#{val}\"" }.join(", ")
  File.open(config, "w") do |f|
    f.puts config_file_contents(robot_class_name, options_str)
  end
  #Make the appengine web xml file
  puts "Creating appengine config file #{File.expand_path(appengine_web)}"
  File.open(appengine_web, "w") do |f|
    f.puts appengine_web_contents(robot_name)
  end
  #Make the public folder for static resources
  puts "Creating public folder"
  Dir.mkdir(public_folder)
  #Copy jars over
  puts "Creating lib directory #{File.expand_path(lib)}"
  Dir.mkdir(lib)
  jars.each do |jar|
    puts "Adding jar #{jar}"
    File.copy(File.join(jar_dir, jar), File.join(lib, jar))
  end
  #Make the wabler config file
  puts "Creating config directory #{File.expand_path(config_dir)}"
  Dir.mkdir(config_dir)
  warble_file = File.join(config_dir, "warble.rb")
  puts "Creating warble config file #{File.expand_path(warble_file)}"
  File.open(warble_file, "w") do |f|
    f.puts warble_config_contents()
  end
end

def robot_file_contents(robot_name, module_name)
  <<-ROBOT
require 'rubygems'
require 'rave'

module #{module_name}
  class Robot < Rave::Models::Robot
    
    ME = "#{robot_name}@appspot.com"
    
    #Define handlers here:
    # e.g. if the robot should act on a DOCUMENT_CHANGED event:
    # 
    # def document_changed(event, context)
    #   #Do some stuff
    # end
    # 
    # Events are: 
    # 
    # WAVELET_BLIP_CREATED, WAVELET_BLIP_REMOVED, WAVELET_PARTICIPANTS_CHANGED,
    # WAVELET_TIMESTAMP_CHANGED, WAVELET_TITLE_CHANGED, WAVELET_VERSION_CHANGED,
    # BLIP_CONTRIBUTORS_CHANGED, BLIP_DELETED, BLIP_SUBMITTED, BLIP_TIMESTAMP_CHANGED,
    # BLIP_VERSION_CHANGED, DOCUMENT_CHANGED, FORM_BUTTON_CLICKED
    #
    # If you want to name your event handler something other than the default name, 
    # or you need to have more than one handler for an event, you can register handlers
    # in the robot's constructor:
    #
    # def initialize(options={})
    #   super
    #   register_handler(Rave::Models::Event::DOCUMENT_CHANGED, :custom_doc_changed_handler)
    # end
    # 
    # def custom_doc_changed_handler(event, context)
    #   #Do some stuff
    # end
    # 
    # Note: Don't forget to call super if you define #initialize
    
  end
end
ROBOT
end

def config_file_contents(robot_class_name, options_str)
  <<-CONFIG
require 'robot'
run #{robot_class_name}.new( #{options_str} )
CONFIG
end

def appengine_web_contents(robot_name)
  <<-APPENGINE
<?xml version="1.0" encoding="utf-8"?>
<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
    <application>#{robot_name}</application>
    <version>1</version>
    <static-files />
    <resource-files />
    <sessions-enabled>false</sessions-enabled>
    <system-properties>
      <property name="jruby.management.enabled" value="false" />
      <property name="os.arch" value="" />
      <property name="jruby.compile.mode" value="JIT"/> <!-- JIT|FORCE|OFF -->
      <property name="jruby.compile.fastest" value="true"/>
      <property name="jruby.compile.frameless" value="true"/>
      <property name="jruby.compile.positionless" value="true"/>
      <property name="jruby.compile.threadless" value="false"/>
      <property name="jruby.compile.fastops" value="false"/>
      <property name="jruby.compile.fastcase" value="false"/>
      <property name="jruby.compile.chainsize" value="500"/>
      <property name="jruby.compile.lazyHandles" value="false"/>
      <property name="jruby.compile.peephole" value="true"/>
   </system-properties>
</appengine-web-app>
APPENGINE
end

def warble_config_contents
  <<-WARBLE
Warbler::Config.new do |config|
  config.gems = %w( rave json-jruby rack builder )
  config.includes = %w( robot.rb appengine-web.xml )
end
WARBLE
end