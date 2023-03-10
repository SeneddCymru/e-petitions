module TranslationHelper
  class LanguageSwitcherTag
    attr_reader :template

    delegate :t, :request, to: :template
    delegate :path_parameters, to: :request
    delegate :query_parameters, to: :request
    delegate :locale, to: :I18n

    def initialize(template)
      @template = template
    end

    def render
      t(:language_switcher_html, scope: :"ui.header", url: url)
    end

    private

    def url
      template.public_send(helper, translate(query_parameters))
    end

    def route
      path_parameters[:route]
    end

    def helper
      locale == :"cy-GB" ? :"#{route}_en_url" : :"#{route}_cy_url"
    end

    def translate(params)
      params.inject({}) do |hash, (key, value)|
        hash[key] = translate_param(key, value)
        hash
      end
    end

    def translate_param(key, value)
      return value unless key == "topic"

      if topic = Topic.find_by(code: value)
        I18n.locale == :"en-GB" ? topic.code_cy : topic.code_en
      else
        value
      end
    end
  end

  def language_switcher_tag
    LanguageSwitcherTag.new(self).render
  end

  if Site.translation_enabled?
    def t(key, **options)
      keys = I18n.normalize_keys(I18n.locale, key, options[:scope])
      scope = keys[1]

      return super unless scope == :ui

      url  = edit_admin_language_url(keys.shift, keys.join("."))
      data = { translation_link: url }

      content_tag(:span, "", data: data) + h(super)
    end
  end
end
