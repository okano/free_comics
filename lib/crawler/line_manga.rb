module Crawler::LineManga extend self

require "#{Rails.root}/app/models/series"
require "#{Rails.root}/app/models/topic"
require 'date'
require 'open-uri'
require 'nokogiri'

  def batch
    #p 'this is test crawler.'
    #s = Series.create(title: "test title", author: "author-X", summary:"abc
#def
#ghi", thumbnail_url: "http://example.com/abc")

    # 日付からURLを得る
    url = FreeComics::Application.config.url_base_linemanga + (Date.today.wday + 1).to_s

    # シリーズ一覧を得る
    charset = nil
    html = open(url) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end
    #File.open("html.txt", "w") {|f| f.puts(html) }

    doc = Nokogiri::HTML.parse(html, nil, charset)
    ## File.open("html-parse.txt", "w") {|f| f.puts(doc) }
    doc.css('div .mdCMN04Item').each do |node|
      p '--------'
      #p node
      title = node.css('h2').text if node.css('h2')
      author = node.css('div .mdCMN04Name').text if node.css('div .mdCMN04Name')
      thumbnail_url = node.css('img').attribute("data-lz-src").value if node.css('img').attribute("data-lz-src")
      p title, author, thumbnail_url
      series_sid_str = node.css('a').attribute("href").value if node.css('a').attribute("href")
      series_sid = series_sid_str.split("/product/periodic?id=").last if series_sid_str

      # 初めてのシリーズなら、DBに保存して、サムネイル画像をCDNに保存
      if !Series.find_by(title: title) then
        Series.create(sid: series_sid, title: title, author: author, summary:"", thumbnail_url: thumbnail_url)
      # シリーズ内の各話を取得
      end
    end



  end
end
