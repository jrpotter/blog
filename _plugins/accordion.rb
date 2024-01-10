class Accordion < Liquid::Block
  def initialize(tag_name, block_options, liquid_options)
    super
    @header = block_options.strip
  end

  def render(context)
    @context = context
    @text = super
    internal_render
  end

  def internal_render
  <<~SUMMARY
    <details style="border: 1px dashed rgba(155, 155, 155, 0.8); padding: 6px;">
      <summary>
        <strong>#{@header}</strong>
      </summary>
      <div style="padding-top: 12px;">
        #{markdown_converter.convert(@text)}
      </div>
    </details>
  SUMMARY
  end

  def markdown_converter
    @context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
  end
end

Liquid::Template.register_tag('accordion', Accordion)
