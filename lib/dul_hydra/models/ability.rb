module DulHydra::Models
  module Ability
    extend ActiveSupport::Concern

    included do
      self.ability_logic += DulHydra.extra_ability_logic if DulHydra.extra_ability_logic
    end

    def read_permissions
      super
      can :read, ActiveFedora::Datastream do |ds|
        can? :read, ds.pid
      end
    end

    def edit_permissions
      super
      can [:edit, :update, :destroy], ActiveFedora::Datastream do |action, ds|
        can? action, ds.pid
      end
    end

    def export_sets_permissions
      can :manage, ExportSet, :user_id => current_user.id
    end

    def preservation_events_permissions
      can :read, PreservationEvent do |pe|
        pe.for_object? and can?(:read, pe.for_object)
      end
    end
    
    def batches_permissions
      can :manage, DulHydra::Batch::Models::Batch, :user_id => current_user.id
    end

    def download_permissions
      can :download, ActiveFedora::Datastream do |ds|
        # The "content" datastream of a Component object
        if ds.dsid == DulHydra::Datastreams::CONTENT and ds.digital_object.original_class == Component
          current_user.member_of? DulHydra.component_download_group
        # All other datastreams
        else
          can? :read, ds
        end
      end
    end

    # Mimics Hydra::Ability#read_permissions
    def discover_permissions
      can :discover, String do |pid|
        test_discover(pid)
      end

      can :discover, ActiveFedora::Base do |obj|
        test_discover(obj.pid)
      end 
      
      can :discover, SolrDocument do |obj|
        cache.put(obj.id, obj)
        test_discover(obj.id)
      end 
    end

    # Mimics Hydra::Ability#test_read + Hydra::PolicyAwareAbility#test_read in one method
    def test_discover(pid)
      logger.debug("[CANCAN] Checking discover permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & discover_groups(pid)
      result = !group_intersection.empty? || discover_persons(pid).include?(current_user.user_key)
      result || test_discover_from_policy(pid)
    end 

    # Mimics Hydra::PolicyAwareAbility#test_read_from_policy
    def test_discover_from_policy(object_pid)
      policy_pid = policy_pid_for(object_pid)
      if policy_pid.nil?
        return false
      else
        logger.debug("[CANCAN] -policy- Does the POLICY #{policy_pid} provide DISCOVER permissions for #{current_user.user_key}?")
        group_intersection = user_groups & discover_groups_from_policy(policy_pid)
        result = !group_intersection.empty? || discover_persons_from_policy(policy_pid).include?(current_user.user_key)
        logger.debug("[CANCAN] -policy- decision: #{result}")
        result
      end
    end 

    # Mimics Hydra::Ability#read_groups
    def discover_groups(pid)
      doc = permissions_doc(pid)
      return [] if doc.nil?
      dg = edit_groups(pid) | read_groups(pid) | (doc[self.class.discover_group_field] || [])
      logger.debug("[CANCAN] discover_groups: #{dg.inspect}")
      return dg
    end

    # Mimics Hydra::PolicyAwareAbility#read_groups_from_policy
    def discover_groups_from_policy(policy_pid)
      policy_permissions = policy_permissions_doc(policy_pid)
      discover_group_field = Hydra.config[:permissions][:inheritable][:discover][:group]
      dg = edit_groups_from_policy(policy_pid) | read_groups_from_policy(policy_pid) | ((policy_permissions == nil || policy_permissions.fetch(discover_group_field, nil) == nil) ? [] : policy_permissions.fetch(discover_group_field, nil))
      logger.debug("[CANCAN] -policy- discover_groups: #{dg.inspect}")
      return dg
    end

    # Mimics Hydra::Ability#read_persons
    def discover_persons(pid)
      doc = permissions_doc(pid)
      return [] if doc.nil?
      dp = edit_persons(pid) | read_persons(pid) | (doc[self.class.discover_person_field] || [])
      logger.debug("[CANCAN] discover_persons: #{dp.inspect}")
      return dp
    end

    def discover_persons_from_policy(policy_pid)
      policy_permissions = policy_permissions_doc(policy_pid)
      discover_individual_field = Hydra.config[:permissions][:inheritable][:discover][:individual]
      dp = edit_persons_from_policy(policy_pid) | read_persons_from_policy(policy_pid) | ((policy_permissions == nil || policy_permissions.fetch(discover_individual_field, nil) == nil) ? [] : policy_permissions.fetch(discover_individual_field, nil))
      logger.debug("[CANCAN] -policy- discover_persons: #{dp.inspect}")
      return dp
    end

    module ClassMethods
      def discover_person_field 
        Hydra.config[:permissions][:discover][:individual]
      end

      def discover_group_field
        Hydra.config[:permissions][:discover][:group]
      end
    end

  end
end
