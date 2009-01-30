#ssh -f -g -L 31337:127.0.0.1:3306  \
#        -L 31338:127.0.0.1:389 \
#        -L 22122:192.168.30.4:22122 \
#        tunnel@www1.networktext.com \
#        ./keepalive.sh

require 'yaml'
require 'socket'

class DigDug
    CONFIG_DEFAULTS={
        :sleep_time=>10,
        :ssh_command=>'ssh',
        :ssh_flags=>['-g'],
        :background_command=>'./keepalive.sh',
        :user=>'adrian',
        :host=>'localhost',
        :tunnels=>[{:type=>:local,:local_port=>31337,:remote_port=>3306,:remote_host=>'127.0.0.1'}]
    }
    
    def initialize
        @config=CONFIG_DEFAULTS.merge(File.open( 'config.yml' ) { |yf| YAML::load( yf ) })
        @threads=[]
        @running=true
    end
    
    def shutdown; @running=false; end
    
    def tunnel_command(t)
           case t[:type]; when :local; '-L '; when :remote; '-R '; end+t[:local_port].to_s+':'+t[:remote_host]+':'+t[:remote_port].to_s
    end
    
    def open_tunnel(tunnel)
        printf "Opening tunnel to #{tunnel[:remote_host]}:#{tunnel[:remote_port]}...\n"
        cmd = @config[:ssh_command]
        flags = @config[:ssh_flags]
        flags << tunnel_command(tunnel)
        flags << @config[:user]+'@'+@config[:host]
        flags << @config[:background_command]
        flags << ">/dev/null"
        @threads << Kernel.fork {
            system(cmd, *flags)
        }
    end
    
    def bring_up_tunnels
       @config[:tunnels].collect{|t| 
           if not tunnel_alive?(t) then
             open_tunnel(t)
           end
        }
    end
    
    def tunnel_alive?(tunnel)
        begin
            case tunnel[:type]
            when :local
                t=TCPSocket.open('localhost',tunnel[:local_port])
                t.close
            when :remote 
            end
        
            true
        rescue Errno::ECONNREFUSED
            false
        end
    end
    
    def run
        begin
       while @running
           bring_up_tunnels
           sleep @config[:sleep_time]
       end 
       shutdown
        rescue Interrupt
         shutdown
        end
    end
    
    def shutdown
       @threads.each {|t|
           Process.kill(9,t)
           Process.wait(t)
           }
    end
end

d=DigDug.new
d.run