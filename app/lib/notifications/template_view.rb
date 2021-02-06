module Notifications
  class TemplateView
    CONTROLLER_CLASS = Class.new(ActionController::Base)
    CONTEXT_CLASS = Class.new(ActionView::Base.with_empty_template_cache) do
      include Notifications::Markdown
    end

    attr_reader :context
    delegate :render, to: :context

    def initialize(assigns)
      @context = CONTEXT_CLASS.new(lookup_context, assigns, controller)
    end

    private

    def context
      @context ||= CONTEXT_CLASS.new(lookup_context, assigns, CONTROLLER_CLASS.new)
    end

    def lookup_context
      ActionView::LookupContext.new('app/views')
    end

    def controller
      CONTROLLER_CLASS.new
    end
  end
end
