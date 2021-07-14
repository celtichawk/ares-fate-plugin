module AresMUSH
  module Fate
    
    def self.rating_ladder
      {
        "Legendary" => 8,
        "Epic" => 7,
        "Fantastic" => 6,
        "Superb" => 5,
        "Great" => 4,
        "Good" => 3,
        "Fair" => 2,
        "Average" => 1,
        "Mediocre" => 0,
        "Poor" => -1,
        "Terrible" => -2
      }
    end
    
    def self.roll_fate_die
      die = [ -1, -1, 0, 0, 1, 1 ].shuffle.first
    end
    
    def self.roll_fate_dice
      dice = []
      4.times.each do |i|
        dice << Fate.roll_fate_die
      end
      total = dice.inject(0){|sum, x| sum + x }

      Global.logger.debug "Rolled fate dice: #{dice} = #{total}"
      total
    end
    
    def self.roll_skill(char, roll_str)
      match = /^(?<ability>[^\+\-]+)\s*(?<modifier>[\+\-]\s*\d+)?$/.match(roll_str)
      return nil if !match
      
      ability = match[:ability].strip
      modifier = match[:modifier].nil? ? 0 : match[:modifier].gsub(/\s+/, "").to_i
      if Fate.rating_ladder[ability]
        rating = Fate.rating_ladder[ability]
      elsif char
        rating = Fate.skill_rating(char, ability)
      else 
        rating = 0
      end
      dice = Fate.roll_fate_dice
      
      total = dice + modifier + rating
      name = char ? char.name : "NPC"
      Global.logger.debug "Rolling #{roll_str} for #{name}: abil=#{ability} rating=#{rating} mod=#{modifier} dice=#{dice} total=#{total}"
        
      total
    end
    
    def self.can_manage_abilities?(actor)
      return false if !actor
      actor.has_permission?("manage_apps")
    end
        
    def self.name_to_rating(name)
      return nil if !name
      return name.to_i if name.is_integer?
      name = name.titlecase
      if (Fate.rating_ladder.has_key?(name))
        return Fate.rating_ladder[name]
      end
      return nil
    end
    
    def self.is_valid_skill_rating?(rating)
      Fate.rating_ladder.any? { |n, r| r == rating }
    end
    
    def self.skills
      Global.read_config('fate', 'skills')
    end
    
    def self.is_valid_skill_name?(name)
      return true if Fate.skills.any? { |s| s['name'].downcase == name.downcase }
      return true if name.is_integer?
      return false
    end
    
    def self.update_refresh(model)
      num_stunts = (model.fate_stunts || {}).count
      if (num_stunts <= 3)
        model.update(fate_refresh: 4)
      elsif (num_stunts == 4)
        model.update(fate_refresh: 3)
      else
        model.update(fate_refresh: 2)
      elsif (num_stunts == 5)
        model.update(fate_refresh: 1)
    end
    
    def self.skill_rating(model, skill)
      (model.fate_skills || {})[skill.titlecase] || 0
    end
    
    def self.rating_name(rating)
      if (rating > 8)
        return "Beyond Legendary"
      end
      
      if (rating < -2)
        return "Beyond Terrible"
      end
      
      return Fate.rating_ladder.key(rating)
    end
    
    def self.physical_stress_thresh(model)
      skill = Global.read_config('fate', 'physical_stress_skill')
      skill_rating = Fate.skill_rating(model, skill)
      if (skill_rating == 1 || skill_rating == 2)
        return 3
      elsif (skill_rating >= 3)
        return 4
      else
        return 2
      end
    end
    
    def self.mental_stress_thresh(model)
      skill = Global.read_config('fate', 'mental_stress_skill')
      skill_rating = Fate.skill_rating(model, skill)
      if (skill_rating == 1 || skill_rating == 2)
        return 3
      elsif (skill_rating >= 3)
        return 4
      else
        return 2
      end
    end
    
    def self.refresh_fate
      Chargen.approved_chars.each { |c| c.update(fate_points: c.fate_refresh) }
    end
    
    def self.emit_results(room, message)
      room.emit message
      if (room.scene)
        Scenes.add_to_scene(room.scene, message)
      end
    end
    
    def self.roll_opposed(char, roll_str1, target, roll_str2)
      roll1 = Fate.roll_skill(char, roll_str1)
      if (!roll1)
        return nil
      end
      
      opponent = Character.find_one_by_name(target)
      roll2 = Fate.roll_skill(opponent, roll_str2)

      if (!roll2)
        return nil
      end
      
      result1 = Fate.rating_name(roll1)
      result2 = Fate.rating_name(roll2)
      
      if (roll1 == roll2)
        overall = t('fate.opposed_draw')
      elsif (roll1 > roll2)
        overall = t('fate.opposed_win', :name => char.name)
      else
        overall = t('fate.opposed_win', :name => target)
      end
      
      {
       :roll1 => roll1,
       :roll2 => roll2,
       :result1 => result1,
       :result2 => result2,
       :overall => overall 
      }
    end
    
    def self.uninstall_plugin
      Character.all.each do |c|
        c.update(fate_aspects: nil)
        c.update(fate_stunts: nil)
        c.update(fate_skills: nil)
        c.update(fate_points: nil)
        c.update(fate_refresh: nil)        
      end
    end
  end
end
