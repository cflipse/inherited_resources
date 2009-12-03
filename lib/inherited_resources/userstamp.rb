module InheritedResources
  module Userstamp
    def create_resource(obj)
      record_user(obj, :updater, :creator)
      super
    end

    def update_resource(obj, *args)
      record_user(obj, :updater)
      super
    end

    def destroy_resource(obj, *args)
      record_user(obj, :deleter)
      super
    end

  protected
    def record_user(obj, *roles)
      user = send(self.userstamp_configuration[:current_user])
      roles.each do |role|
        writer = "#{self.userstamp_configuration[role]}="
        obj.send(writer, user) if obj.respond_to?(writer)
      end
    end

  end
end
