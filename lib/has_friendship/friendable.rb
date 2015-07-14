module HasFriendship
  module Friendable

    def friendable?
      false
    end

    def has_friendship
      
      class_eval do
        has_many :friendships, as: :friendable, class_name: "HasFriendship::Friendship", dependent: :destroy
        has_many :friends, 
                  -> { where friendships: { status: 'accepted' } },
                  through: :friendships

        has_many :requested_friends,
                  -> { where friendships: { status: 'requested' } },
                  through: :friendships,
                  source: :friend

        has_many :pending_friends,
                  -> { where friendships: { status: 'pending' } },
                  through: :friendships,
                  source: :friend

        def self.friendable?
          true
        end
      end

      include HasFriendship::Friendable::InstanceMethods
      include HasFriendship::Extender
    end

    module InstanceMethods

      def friend_request(friend)
        unless self == friend || HasFriendship::Friendship.exist?(self, friend)
          transaction do
            HasFriendship::Friendship.create(friendable_id: self.id, friendable_type: self.class.base_class.name, friend_id: friend.id, status: 'pending')
            HasFriendship::Friendship.create(friendable_id: friend.id, friendable_type: friend.class.base_class.name, friend_id: self.id, status: 'requested')
          end
        end
      end

      def accept_request(friend)
        transaction do
          pending_friendship = HasFriendship::Friendship.find_friendship(friend, self)
          pending_friendship.status = 'accepted'
          pending_friendship.save

          requeseted_friendship = HasFriendship::Friendship.find_friendship(self, friend)
          requeseted_friendship.status = 'accepted'
          requeseted_friendship.save
        end
      end

      def decline_request(friend)
        transaction do
          HasFriendship::Friendship.find_friendship(friend, self).destroy
          HasFriendship::Friendship.find_friendship(self, friend).destroy
        end
      end

      def remove_friend(friend)
        transaction do
          HasFriendship::Friendship.find_friendship(friend, self).destroy
          HasFriendship::Friendship.find_friendship(self, friend).destroy
        end
      end
      
     def can_friend_with?(friend)
        self != friend && 
        HasFriendship::Friendship.find_friendship(self, friend).blank? && 
        HasFriendship::Friendship.find_friendship(friend, self).blank?
     end


    end
  end
end
