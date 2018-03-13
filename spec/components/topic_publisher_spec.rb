require 'topic_publisher'
require 'rails_helper'

describe TopicPublisher do

  context "shared drafts" do
    let(:shared_drafts_category) { Fabricate(:category) }
    let(:category) { Fabricate(:category) }

    before do
      SiteSetting.shared_drafts_category = shared_drafts_category.id
    end

    context "publishing" do
      let(:topic) { Fabricate(:topic, category: shared_drafts_category, visible: false) }
      let(:shared_draft) { Fabricate(:shared_draft, topic: topic, category: category) }
      let(:moderator) { Fabricate(:moderator) }

      it "will publish the topic properly" do
        TopicPublisher.new(topic, moderator, shared_draft.category_id).publish!

        topic.reload
        expect(topic.category).to eq(category)
        expect(topic).to be_visible
        expect(topic.shared_draft).to be_blank
        expect(UserHistory.where(
          acting_user_id: moderator.id,
          action: UserHistory.actions[:topic_published]
        )).to be_present
      end
    end

  end

end
