# encoding: utf-8
require 'nokogiri'
require 'yaml'
require 'json'

Dir.glob('./source/atm*') do |file|
  
  puts file
  doc = Nokogiri::HTML(open(file))

  def t(node)
    node.text.gsub('　',' ').strip if node
  end

  def parse_simple_table(table)
    json={}
    tenderer=nil
    table.css('tr').each do |tr|
      th =t(tr.css("th"))
      td =t(tr.css("td").first)
      if th =~ /標廠商\d/ && td == ''
        json[th]={}
        tenderer=th
      end
      if tenderer
        (json[tenderer]||={})[th] = td
      else
        json[th] = td
      end
    end
    json
  end

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
      current_json.merge! parse_simple_table( tr.css('table'))
    else
      if t(tr.xpath("th")) != ''
        current_json[t(tr.xpath("th"))] = t(tr.css("td").first)
      end
    end

  end
  basname=File.basename(file)
  open(File.join('json', basname),'w'){|f| f.write(JSON.dump(json)) }
  open(File.join('yaml', basname),'w'){|f| f.write(YAML.dump(json)) }
end
