require 'yaml'
require 'socket'

class DigDug
    VERSION=0.1
    
    CONFIG_DEFAULTS={
        :sleep_time=>10,
        :ssh_command=>'ssh',
        :ssh_flags=>['-g'],
        :background_command=>'./keepalive.sh',
        :user=>'adrian',
        :host=>'localhost',
        :tunnels=>[{:type=>:local,:local_port=>31337,:remote_port=>3306,:remote_host=>'127.0.0.1'}]
    }
    
    def initialize(config='config.yml')
        @config=CONFIG_DEFAULTS.merge(File.open(config) { |yf| YAML::load( yf ) })
        @threads=[]
        @running=true
    end
    
    def shutdown; @running=false; end
    
    def tunnel_command(t)
           case t[:type]; when :local; '-L '; when :remote; '-R '; end+t[:local_port].to_s+':'+t[:remote_host]+':'+t[:remote_port].to_s
    end
    
    def close_tunnel(tunnel)
       if tunnel[:thread] then
           Process.kill(9,t)
           Process.wait(t)
       end
    end
    
    def open_tunnel(tunnel)
        printf "Opening tunnel to #{tunnel[:remote_host]}:#{tunnel[:remote_port]}...\n"
        cmd = @config[:ssh_command]
        flags = @config[:ssh_flags]
        flags << tunnel_command(tunnel)
        flags << @config[:user]+'@'+@config[:host]
        flags << @config[:background_command]
        flags << ">/dev/null"
        tunnel[:thread] = Kernel.fork {
            system(cmd, *flags)
        }
        @threads << tunnel[:thread]
    end
    
    def bring_up_tunnels
       @config[:tunnels].collect{|t| 
           if not tunnel_alive?(t) then
             close_tunnel(t)
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
       while @running
           bring_up_tunnels
           sleep @config[:sleep_time]
       end 
       shutdown
    end
    
    def shutdown
        @running=false
        @threads.each {|t|
            begin
               Process.kill(9,t)
               Process.wait(t)
            rescue
            end
           }
    end
end