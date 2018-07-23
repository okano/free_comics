module Crawler::LineManga extend self

require "#{Rails.root}/app/models/series"
require "#{Rails.root}/app/models/topic"
require "#{Rails.root}/lib/crawler/my_aws"
require 'date'
require 'open-uri'
require 'tempfile'
require 'nokogiri'
require 'json'

  def batch
    # 日付からURLを得る
    url = FreeComics::Application.config.url_base_linemanga
        + FreeComics::Application.config.url_list_linemanga
        + (Date.today.wday + 1).to_s
    # シリーズ一覧を得る
    doc = parse_html(url)
    # 各シリーズごとに処理
    doc.css('div .mdCMN04Item').each do |node|
      p '--------'
      #p node
      title = node.css('h2').text if node.css('h2')
      author = node.css('div .mdCMN04Name').text if node.css('div .mdCMN04Name')
      thumbnail_org_url = node.css('img').attribute("data-lz-src").value if node.css('img').attribute("data-lz-src")
      p title, author, thumbnail_org_url
      series_sid_str = node.css('a').attribute("href").value if node.css('a').attribute("href")
      series_sid = series_sid_str.split("/product/periodic?id=").last if series_sid_str
      p series_sid

      detail_url = FreeComics::Application.config.url_base_linemanga
                 + FreeComics::Application.config.url_detail_linemanga
                 + series_sid
      doc_detail = parse_html(detail_url)

      # 初めてのシリーズなら、サムネイル画像をCDNに保存して、DBに保存
      if !Series.find_by(title: title) then
        # サムネイル画像の保存
        open(thumbnail_org_url) { |image|
          Tempfile.open { |t|
            p 'thumbnail_org_url_basename=' + File.basename(thumbnail_org_url)
            p 't.path=' + t.path
            t.binmode
            t.write image.read

            # S3へアップロード
            upload_filename = SecureRandom.urlsafe_base64 + File.basename(thumbnail_org_url)
            @aws ||= MyAws.new  # 初回のみ初期設定
            @s3_url = @aws.send(FreeComics::Application.config.cdn_folder_linemanga,
                                t.path,
                                upload_filename)

          }
        }
        # 概要を得る
        summary = doc_detail.css('.MdMNG04Intro').text if doc_detail.css('.MdMNG04Intro')
        p "summary=" + summary
        # サムネイル画像のURL付きでDBに保存
        Series.create(sid: series_sid, title: title, author: author,
                      summary:summary, thumbnail_url: @s3_url)
      end
      # シリーズ内の各話を取得
      topic_all_url = doc_detail.css('div .mdMNG03Btn > div > a').attribute("href").value if doc_detail.css('div .mdMNG03Btn > div > a')
      if topic_all_url then
        # 詳細リスト(5話以上ある場合)があれば、そちらを使用する
        detail_all_url = FreeComics::Application.config.url_base_linemanga
                       + FreeComics::Application.config.url_detail_all_linemanga
                       + series_sid)
        doc_detail_all = parse_html(detail_all_url)
        hash = JSON.parse(doc_detail_all)
        p JSON.pretty_generate(hash)
        File.open("json.txt", "w") {|f| f.puts(JSON.pretty_generate(hash)) }
      else
        # 詳細リスト(5話以上)が無い場合
        doc_detail.css('div .MdMNG03List > ul > li').each do |node2|
          topic_number = node2.css('h3 > b').text if node2.css('h3 > b')
          topic_title = node2.css('h3 > span').text if node2.css('h3 .span')
          topic_thumbnail_org_url = node2.css('img').attribute('src').value if node2.css('img').attribute('src')
          topic_status = node2.css('.mdMNG03Status')
          p "topic_status=" + topic_status
          if topic_status then
            p topic_number
            p topic_title
          end
        end
      end
      xx
    end
  end

  def parse_html(url)
    #p "url=" + url
    charset = nil
    html = open(url) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end
    #File.open("html.txt", "w") {|f| f.puts(html) }

    doc = Nokogiri::HTML.parse(html, nil, charset)
    ## File.open("html-parse.txt", "w") {|f| f.puts(doc) }
  end
end
