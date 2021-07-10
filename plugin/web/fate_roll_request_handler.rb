module AresMUSH
  module Fate
    class FateRollRequestHandler
      def handle(request)
        scene = Scene[request.args[:scene_id]]
        enactor = request.enactor
        sender_name = request.args[:sender]
        skill = InputFormatter.titlecase_arg(request.args[:skill])
        vsChar = InputFormatter.titlecase_arg(request.args[:vsChar])
        vsSkill = InputFormatter.titlecase_arg(request.args[:vsSkill])
        
        error = Website.check_login(request)
        return error if error

        request.log_request
        
        sender = Character.named(sender_name)
        if (!sender)
          return { error: t('webportal.not_found') }
        end
        
        if (!AresCentral.is_alt?(sender, enactor))
          return { error: t('dispatcher.not_allowed') }
        end
        
        if (!scene)
          return { error: t('webportal.not_found') }
        end
        
        if (!Scenes.can_read_scene?(enactor, scene))
          return { error: t('scenes.access_not_allowed') }
        end
        
        if (scene.completed)
          return { error: t('scenes.scene_already_completed') }
        end
        
        if (vsChar.blank?)
          roll = Fate.roll_skill(sender, skill)
          if (!roll)
            return { error: t('fate.invalid_roll_str') }
          end
          result = Fate.rating_name(roll)
          message = t('fate.roll_results', :name => sender.name, :result => result, :roll => roll, :roll_str => skill)
          Fate.emit_results scene.room, message
        else
          
          results = Fate.roll_opposed(sender, skill, vsChar, vsSkill)
          if (!results)
            return { error: t('fate.invalid_roll_str') }
          end
          message = t('fate.opposed_roll_results', :name1 => sender.name, 
             :name2 => vsChar, 
             :roll_str1 => skill,
             :roll_str2 => vsSkill,
             :roll1 => results[:roll1],
             :roll2 => results[:roll2],
             :result1 => results[:result1],
             :result2 => results[:result2],
             :overall => results[:overall] )
          Fate.emit_results scene.room, message
         end
           
           
        {
        }
      end
    end
  end
end