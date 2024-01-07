#!/usr/bin/env ruby

class Admonition < Liquid::Block
  def render(context)
    @context = context
    @text = super
    internal_render
  end

  def markdown_converter
    @context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
  end
end

class InfoBlock < Admonition
  def internal_render
  <<~ADMONITION
    <div markdown="1" class="alert alert-info" role="alert">
      <i class="fa fa-info-circle"></i> **Info**
      #{markdown_converter.convert(@text)}
    </div>
  ADMONITION
  end
end

Liquid::Template.register_tag('info', InfoBlock)

class TipBlock < Admonition
  def internal_render
  <<~ADMONITION
    <div markdown="1" class="alert alert-success" role="alert">
      <i class="fa fa-lightbulb"></i> **Tip**
      #{markdown_converter.convert(@text)}
    </div>
  ADMONITION
  end
end

Liquid::Template.register_tag('tip', TipBlock)

class WarningBlock < Admonition
  def internal_render
  <<~ADMONITION
    <div markdown="1" class="alert alert-warning" role="alert">
      <i class="fa fa-exclamation-triangle"></i> **Warning**
      #{markdown_converter.convert(@text)}
    </div>
  ADMONITION
  end
end

Liquid::Template.register_tag('warning', WarningBlock)

class DangerBlock < Admonition
  def internal_render
  <<~ADMONITION
    <div markdown="1" class="alert alert-danger" role="alert">
      <i class="fa fa-exclamation-circle"></i> **Danger**
      #{markdown_converter.convert(@text)}
    </div>
  ADMONITION
  end
end

Liquid::Template.register_tag('danger', DangerBlock)
