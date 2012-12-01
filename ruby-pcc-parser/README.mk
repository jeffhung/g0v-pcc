將 http://web.pcc.gov.tw/tps/pss/tender.do?method=goSearch&searchMode=common&searchType=advance&searchTarget=ATM  搜尋得到的資料抓下來後放到 source, 執行 ruby parser.rb 會自動產生 JSON 與 YAML 的結果在對應的目錄中

需要的 rubygem
* nokogiri
