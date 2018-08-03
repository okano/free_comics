require 'nokogiri'

require 'open-uri'
class MyUtil
  def self.parse_html(url, option = {})
    #p "url=" + url
    charset = nil
    html = open(url, option) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end
    #File.open("html.txt", "w") {|f| f.puts(html) }

    doc = Nokogiri::HTML.parse(html, nil, charset)
    ## File.open("html-parse.txt", "w") {|f| f.puts(doc) }
  end

  # 本番環境では、プロキシ経由でURLにアクセスする
  def self.parse_html_with_proxy(url)
    option = {}
    if Rails.env.production? then
      if !ENV['PROXY_SERVER'].blank?
        proxy =  'http://'
        proxy += ENV['PROXY_SERVER']
        proxy += ':' + ENV['PROXY_PORT'] if !ENV['PROXY_PORT'].blank?
        proxy += '/'
        if !ENV['PROXY_USERNAME'].blank? and !ENV['PROXY_PASSWORD'].blank? then
          # BASIC認証付きのプロキシ
          option = {:proxy_http_basic_authentication => [proxy, ENV['PROXY_USERNAME'], ENV['PROXY_PASSWORD']]}
        else
          option = {:proxy => proxy}
        end
      end
    end
    p 'parse_html_with_proxy  option=' + option.to_s
    self.parse_html(url, option)
  end
end