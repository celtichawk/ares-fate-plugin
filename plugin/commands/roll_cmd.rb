module AresMUSH    
  module Fate
    class RollCmd
      include CommandHandler
  
      attr_accessor :roll_str
      
      def parse_args
        self.roll_str = titlecase_arg(cmd.args)
      end
            
      def required_args
        [self.roll_str]
      end
      
      def handle
        roll = Fate.roll_skill(enactor, self.roll_str)
        if (!roll)
          client.emit_failure t('fate.invalid_roll_str')
          return
        end
        
        result = Fate.rating_name(roll)
        Fate.emit_results enactor.room, t('fate.roll_results', :name => enactor_name, :result => result, :roll => roll, :roll_str => self.roll_str)
      end
    end
  end
end