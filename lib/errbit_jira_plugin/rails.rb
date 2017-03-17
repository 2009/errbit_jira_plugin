if defined?(Rails)
  module ErrbitJiraPlugin
    module Rails
      class Engine < ::Rails::Engine
        paths["app/views"] = "views"
      end
    end
  end
end
