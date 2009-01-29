#ssh -f -g -L 31337:127.0.0.1:3306  \
#        -L 31338:127.0.0.1:389 \
#        -L 22122:192.168.30.4:22122 \
#        tunnel@www1.networktext.com \
#        ./keepalive.sh

require 'yaml'

class DigDug
    CONFIG_DEFAULTS={
        :ssh_command=>'ssh',
        :ssh_flags=>'-f -g',
        :user=>'adrian',
        :host=>'localhost',
        :tunnels=>[{:type=>:local,:local_port=>31337,:remote_port=>3306,:remote_host=>'127.0.0.1'}]
    }
    
    def initialize
        p CONFIG_DEFAULTS.to_yaml
        @config=CONFIG_DEFAULTS.merge(File.open( 'config.yml' ) { |yf| YAML::load( yf ) })
        p @config
    end
    
    def tunnel_commands
       @config[:tunnels].collect{|t|
           case t[:type]; when :local; '-L '; when :remote; '-R '; end+t[:local_port].to_s+':'+t[:remote_host]+':'+t[:remote_port].to_s
           }.join(" ")
    end
    
    def open_tunnel
        cmd = @config[:ssh_command]+' '+@config[:ssh_flags]+' '+tunnel_commands+' '+@config[:user]+'@'+@config[:host]+' ./keepalive.sh'
    end
    
    def tunnels_alive?
       @config[:tunnels].each{|t| tunnel_alive?(t)} 
    end
    
    def tunnel_alive?(tunnel)
        
    end
    
end

d=DigDug.new
p d.open_tunnel