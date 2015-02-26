# -*- mode: ruby -*-
require 'nokogiri'
require 'rtf'

def render_html(doc, n, styles, state={})
  case n.name
  when "document", "html", "body"
    n.children.each do |c|
      render_html(doc, c, styles)
    end
  when "p"
    doc.paragraph do |p|
      n.children.each do |c|
        render_html(p, c, styles)
      end
    end
  when "sup", "strong", "b", "sub", "em", "u", "s"
    doc.apply(styles[n.name.intern]) do |c|
      c << n.text
    end
  when "text"
    doc << n.text
  when 'ul'                     
    doc.list :bullets do |l|
      n.children.each do |c|
        render_html(l, c, styles)
      end
    end
  when 'ol'
    doc.list :decimal do |l|
      n.children.each do |c|
        render_html(l, c, styles)
      end
    end
  when 'li'
    doc.item do |i|
      n.children.each do |c|
        render_html(i, c, styles)
      end
    end
  when 'hr'
    doc.table(1,1) do |t|
      #style = RTF::CharacterStyle.new
      #style.font_size = 1
      style = RTF::ParagraphStyle.new
      style.space_after = 0

      cell = t.first.first
      cell.style = style
      cell.top_border_width = 0
      cell.left_border_width = 0
      cell.right_border_width = 0
      cell.bottom_border_width = 0
    end
  when 'br'
    doc.line_break
  when 'a'
    doc.apply(styles['u'.intern]) do |c|
      c << n.text
    end
    doc << " ("
    doc.apply(styles['u'.intern]) do |c|
      c << n.attributes['href'].value
    end
    doc << ")"
  else
    doc << n.text
  end
end

def print_responses(doc, requirement, heading, styles)
  doc.paragraph(styles[:requirement_heading]) do |r|
    #r << "#{heading} " #with indentation in front of every requirement
    r << "#{heading}" #without indentation
    r.apply(styles[:strong]) do |b|
      b << requirement.text_brief.to_s
    end
  end
  if requirement.children.size > 0 then
    requirement.children.order(:position).each_with_index do |child, i|
       #print_responses(doc, child, "#{heading}.#{i+1}", styles) #with numbering
       print_responses(doc, child, "", styles) #without numbering
    end
  else
    html = Nokogiri::HTML(requirement.response_html(@plan))
    render_html(doc, html, styles)
  end
end

def mk_paragraph_style
  s = RTF::ParagraphStyle.new
  yield s
  return s
end

def mk_character_style
  s = RTF::CharacterStyle.new
  yield s
  return s
end

styles = { 
  :bold => mk_character_style {|s|
    s.bold = true
  },
  :footer => mk_paragraph_style {|s|
    s.justification = RTF::ParagraphStyle::CENTER_JUSTIFY 
  },
  :requirement_heading => mk_paragraph_style {|s| },
  :title => mk_paragraph_style {|s|
    s.justification = RTF::ParagraphStyle::CENTER_JUSTIFY 
  },
  :title_char => mk_character_style {|s|
    s.font_size = 36
  },
  :sup => mk_character_style {|s|
    s.superscript = true
  },
  :sub => mk_character_style {|s|
    s.subscript = true
  },
  :b => mk_character_style {|s|
    s.subscript = true
  },
  :strong => mk_character_style {|s|
    s.bold = true
  },
  :em => mk_character_style {|s|
    s.italic = true
  },
  :u => mk_character_style {|s|
    s.underline = true
  },
  :s => mk_character_style {|s|
    s.strike = true
  },
}

#puts styles

doc = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, 'Times New Roman'))
doc.paragraph(styles[:title]) do |p|
  p.apply(styles[:title_char]) do |t|
    t << @plan.name
  end
end
@plan.requirements_template.requirements.order(:position).roots.each_with_index do |req, i|
  # print_responses(doc, req, (i + 1).to_s, styles) #with numbering
  print_responses(doc, req, "", styles) #without numbering
end
footer = doc.footer=RTF::FooterNode.new(doc)
footer.paragraph(styles[:footer]) do |p|
  p << "Generated by the DMPTool on #{Time.now.to_formatted_s(:long)}"
end
doc.to_rtf
