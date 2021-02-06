require 'redcarpet/render_strip'

module Notifications
  module Markdown
    EXTENSIONS = {
      no_intra_emphasis: true, tables: false, fenced_code_blocks: false,
      autolink: true, disable_indented_code_blocks: false, strikethrough: true,
      lax_spacing: false, space_after_headers: true, superscript: true,
      underline: true, highlight: true, quote: true, footnotes: false
    }

    module Renderers
      PLACEHOLDER = /\(\(([a-zA-Z][_a-zA-Z0-9]*)\)\)/

      class HTML < Redcarpet::Render::HTML
        OPTIONS = {
          escape_html: true, filter_html: false,
          hard_wrap: true, xhtml: false, safe_links_only: true,
          no_styles: true, no_images: true, no_links: false,
          with_toc_data: false, prettify: false, link_attributes: {}
        }

        STYLES = {}

        STYLES[:header] = [
          "Margin: 0 0 20px 0",
          "padding: 0",
          "font-size: 27px",
          "line-height: 35px",
          "font-weight: bold",
          "color: #0B0C0C;"
        ].join("; ")

        STYLES[:hrule] = [
          "border: 0",
          "height: 1px",
          "background: #B1B4B6",
          "Margin: 30px 0 30px 0;"
        ].join("; ")

        STYLES[:paragraph] = [
          "Margin: 0 0 20px 0",
          "font-size: 19px",
          "line-height: 25px",
          "color: #0B0C0C;"
        ].join("; ")

        STYLES[:ordered] = [
          "Margin: 0 0 0 20px",
          "padding: 0",
          "list-style-type: decimal;"
        ].join("; ")

        STYLES[:unordered] = [
          "Margin: 0 0 0 20px",
          "padding: 0",
          "list-style-type: disc;"
        ].join("; ")

        STYLES[:list_item] = [
          "Margin: 5px 0 5px",
          "padding: 0 0 0 5px",
          "font-size: 19px",
          "line-height: 25px",
          "color: #0B0C0C;"
        ].join("; ")

        STYLES[:block_quote] = [
          "Margin: 0 0 20px 0",
          "border-left: 10px solid #B1B4B6;",
          "padding: 15px 0 0.1px 15px",
          "font-size: 19px",
          "line-height: 25px;"
        ].join("; ")

        STYLES[:link] = [
          "word-wrap: break-word",
          "color: #1D70B8;"
        ].join("; ")

        def initialize
          super(OPTIONS)
        end

        def preprocess(text)
          text.gsub(PLACEHOLDER) do
            if $1.match?(/url/)
              "[{{#{$1}}}]({{#{$1}}})"
            else
              "{{#{$1}}}"
            end
          end
        end

        def header(text, level)
          if level == 1
            %[<h2 style="#{STYLES[:header]}">#{text}</h2>\n]
          else
            paragraph(text)
          end
        end

        def hrule
          %[<hr style="#{STYLES[:hrule]}">\n]
        end

        def paragraph(text)
          %[<p style="#{STYLES[:paragraph]}">#{nl2br(text)}</p>\n]
        end

        def linebreak
          %[<br />\n]
        end

        def list(content, type)
          tag = type == :ordered ? "ol" : "ul"
          style = STYLES[type]

          <<~HTML
            <table role="presentation" style="padding: 0 0 20px 0;">
              <tr>
                <td style="font-family: Helvetica, Arial, sans-serif;">
                  <#{tag} style="#{style}">
                    #{content}
                  </#{tag}>
                </td>
              </tr>
            </table>
          HTML
        end

        def list_item(text, type)
          %[<li style="#{STYLES[:list_item]}">#{text.strip}</li>\n]
        end

        def block_quote(content)
          %[<blockquote style="#{STYLES[:block_quote]}">\n#{content}</blockquote>\n]
        end

        def link(link, title, content)
          if title.present?
            %[<a href="#{link}" title="#{title}" style="#{STYLES[:link]}">#{content}</a>]
          else
            %[<a href="#{link}" style="#{STYLES[:link]}">#{content}</a>]
          end
        end

        def autolink(link, type)
          type == :email ? link : %[<a href="#{link}" style="#{STYLES[:link]}">#{link}</a>]
        end

        %i[
          codespan double_emphasis emphasis
          underline triple_emphasis strikethrough
          superscript highlight quote
        ].each do |method|
          define_method method do |*args|
            args.first
          end
        end

        def nl2br(text)
          text.gsub("\n") { linebreak }
        end
      end

      class Text < Redcarpet::Render::StripDown
        COLUMN_WIDTH = 65

        def preprocess(text)
          text.gsub(PLACEHOLDER) { "{{#{$1}}}" }
        end

        def header(text, level)
          if level == 1
            text + "\n" + "-" * text.size + "\n"
          else
            paragraph(text)
          end
        end

        def hrule
          "=" * COLUMN_WIDTH + "\n\n"
        end

        def paragraph(text)
          text + "\n\n"
        end

        def list(content, type)
          @counter = 0
          content + "\n"
        end

        def list_item(text, type)
          @counter ||= 0
          @counter += 1

          if type == :ordered
            "#{@counter}. #{text.strip}\n"
          else
            "* #{text.strip}\n"
          end
        end
      end

      class Preheader < Text
        def postprocess(text)
          text.squish.truncate_words(50, omission: "")
        end

        def header(text, level)
          paragraph(text)
        end

        def hrule
          ""
        end

        def list_item(text, type)
          text + "\n"
        end
      end
    end

    def markdown_to_html(markup)
      Redcarpet::Markdown.new(Renderers::HTML.new, EXTENSIONS).render(markup.to_s).html_safe
    end

    def markdown_to_text(markup)
      Redcarpet::Markdown.new(Renderers::Text.new, EXTENSIONS).render(markup.to_s).html_safe
    end

    def preheader(markup)
      Redcarpet::Markdown.new(Renderers::Preheader.new, EXTENSIONS).render(markup.to_s).html_safe
    end
  end
end
