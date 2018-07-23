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
    url = FreeComics::Application.config.url_base_linemanga \
        + FreeComics::Application.config.url_list_linemanga \
        + (Date.today.wday + 1).to_s
    p "url=" + url
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

      detail_url = FreeComics::Application.config.url_base_linemanga \
                 + FreeComics::Application.config.url_detail_linemanga \
                 + series_sid
      doc_detail = parse_html(detail_url)

      # 初めてのシリーズなら、サムネイル画像をCDNに保存して、DBに保存
      series = Series.find_by(title: title)
      if !series then
        # サムネイル画像の保存
        upload_s3(thumbnail_org_url)

        # 概要を得る
        summary = doc_detail.css('.MdMNG04Intro').text if doc_detail.css('.MdMNG04Intro')
        p "summary=" + summary
        # サムネイル画像のURL付きでDBに保存
        @s = Series.create(sid: series_sid, title: title, author: author,
                          summary:summary, thumbnail_url: @s3_url)
        p "series inserted. id=" + @s.id.to_s
      end
      @s ||= Series.find_by(title: title)
      p "title=" + title
      p "Series id=" + @s.id.to_s

      # シリーズ内の各話を取得
      detail_all_url = FreeComics::Application.config.url_base_linemanga \
                     + FreeComics::Application.config.url_detail_all_linemanga \
                     + series_sid
      p "detail_all_url=" + detail_all_url
      doc_detail_all = parse_html(detail_all_url)
      hash = JSON.parse(doc_detail_all)
      File.open("json.txt", "w") {|f| f.puts(JSON.pretty_generate(hash)) }

      hash['result']['rows'].each do |row|
        topic_number = row['volume'].to_s
        topic_title = row['name']
        topic_thumbnail_org_url = row['thumbnail']
        topic_payment = row['allow_charge']
        viewer_url = FreeComics::Application.config.url_base_linemanga
                     + FreeComics::Application.config.url_viewer_linemanga
                     + row['id']
        p "topic_number=" + topic_number
        p "topic_title=" + topic_title
        p "topic_payment=" + topic_payment.to_s
        if !topic_payment then
          if !Topic.find_by(title: topic_title) then
            # 新しいtopicなら、サムネイル画像の保存とDBへの書き込み
            topic_thumbnail_url = upload_s3(topic_thumbnail_org_url)

            store = Store.find_by(name: FreeComics::Application.config.store_name)
            #t = Topic.create(series: @s)
            t = Topic.create(series: @s,
                            store: store,
                            tid: row['id'],
                            title: topic_title,
                            topic_number: "第" + (row['volume']+1).to_s + "話",
                            summary: "",
                            thumbnail_url: topic_thumbnail_url,
                            viewer_url: viewer_url
                            )
            p "topic inserted. id=" + t._id
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

  def upload_s3(original_url)
    # サムネイル画像の保存
    open(original_url) { |image|
      Tempfile.open { |t|
        p 'original_url=' + File.basename(original_url)
        p 't.path=' + t.path
        t.binmode
        t.write image.read

        # S3へアップロード
        upload_filename = SecureRandom.urlsafe_base64 + File.basename(original_url)
        @aws ||= MyAws.new  # 初回のみ初期設定
        @s3_url = @aws.send(FreeComics::Application.config.cdn_folder_linemanga,
                            t.path,
                            upload_filename)
      }
    }
    return @s3_url
  end

end
