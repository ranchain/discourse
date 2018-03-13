export default Ember.Component.extend({
  classNames: 'shared-draft-controls',

  actions: {
    publish() {

      bootbox.confirm(I18n.t('shared_drafts.confirm_publish'), result => {
        if (result) {
          this.get('topic').publish();
        }
      });
    }
  }
});
