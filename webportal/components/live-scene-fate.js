import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  showSkillRoll: false,
  skillToRoll: '',
  vsChar: '',
  vsSkill: '',
  tagName: '',
  gameApi: service(),
  flashMessages: service(),

  actions: {

    rollAbility() {
      let api = this.gameApi;
      let params = {
        scene_id: this.get('scene.id'),
        sender: this.get('scene.poseChar.name'),
        skill: this.skillToRoll,
        vsChar: this.vsChar,
        vsSkill: this.vsSkill
      };
    
      this.set('showSkillRoll', false);
    
      if (this.skillToRoll.length === 0) {
        this.flashMessages.danger("You haven't entered anything to roll.");
        return;
      }
      
      if ((this.vsChar.length === 0 && this.vsSkill.length != 0) || (this.vsChar.length != 0 && this.vsSkill.length === 0)) {
        this.flashMessages.danger("You must enter both a name and skill for a vs roll.");
        return;
      }

      this.set('skillToRoll', '');
      this.set('vsChar', '');
      this.set('vsSkill', '');
          
      api.requestOne('fateRoll', params, null)
      .then( (response) => {
        if (response.error) {
          return;
        }
      });
    }
  }
});
