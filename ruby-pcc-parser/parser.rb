# encoding: utf-8
require 'nokogiri'
require 'yaml'
require 'json'

def t(node)
  if node
    text=node.text
    text.gsub!('　',' ')
    text.gsub!(/[\n\r\t]/,'')
    text.strip! 
    return text 
  end
end

def parse_inner_table(table)
  json={}
  tenderer_type=nil
  table.css('tr').each do |tr|
    th =t(tr.css("th"))
    td =t(tr.css("td").first)

    new_tenderer_start =( th.match /(?<type>.*標廠商)(?<index>\d+)/) 
    if new_tenderer_start && td == ''
      tenderer_type = new_tenderer_start[:type]
      json[tenderer_type] ||= []
      json[tenderer_type] << {}
      next
    end

    if tenderer_type
      json[tenderer_type].last[th] = td
    else
      json[th] = td
    end
  end
  json
end

Dir.glob(ARGV[0]) do |source_path|
  
  puts source_path
  doc = Nokogiri::HTML(open(source_path))

  json={}
  keys=[]
  current_json=json
  rowspan=0
  doc.css('table.tender_table > tbody > tr[class]').each do |tr|
    if rowspan > 0
      rowspan-=1 
    else
      keys.pop 
    end

    current_json=json
    keys.each do |k|
      current_json[k] ||= {}
      current_json=current_json[k]
    end

    if tr.css('td[rowspan]').length > 0
      rowspan = tr.css('td[rowspan]').attr('rowspan').value.to_i - 1
      key=t(tr)
      keys.push key
    elsif tr.css('table').length > 0
      current_json.merge! parse_inner_table( tr.css('table'))
    else
      if t(tr.xpath("th")) != ''
        current_json[t(tr.xpath("th"))] = t(tr.css("td").first)
      end
    end

  end
  basname=File.basename(source_path)
  puts json
  #open(File.join('json', basname),'w'){|f| f.write(JSON.dump(json)) }
  #open(File.join('yaml', basname),'w'){|f| f.write(YAML.dump(json)) }
end
