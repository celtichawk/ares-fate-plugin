module AresMUSH    
  module Fate
    class RollOpposedCmd
      include CommandHandler
  
      attr_accessor :roll_str1, :roll_str2, :target
      
      def parse_args
        return if !cmd.args
        
        self.roll_str1 = titlecase_arg(cmd.args.before(' vs '))
        
        second_section = cmd.args.after(' vs ') || ""
        self.target = titlecase_arg(second_section.before('/'))
        self.roll_str2 = titlecase_arg(second_section.after('/'))
      end
      
      def required_args
        [self.roll_str1, self.roll_str2, self.target]
      end
      
      def handle
        results = Fate.roll_opposed(enactor, self.roll_str1, self.target, self.roll_str2)
        if (!results)
          client.emit_failure t('fate.invalid_roll_str')
          return
        end
        
        Fate.emit_results enactor.room, t('fate.opposed_roll_results', :name1 => enactor_name, 
           :name2 => self.target, 
           :roll_str1 => self.roll_str1,
           :roll_str2 => self.roll_str2,
           :roll1 => results[:roll1],
           :roll2 => results[:roll2],
           :result1 => results[:result1],
           :result2 => results[:result2],
           :overall => results[:overall] )
      end
    end
  end
end