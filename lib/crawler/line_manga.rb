module Crawler::LineManga extend self

require "#{Rails.root}/app/models/series"
require "#{Rails.root}/app/models/topic"
require "#{Rails.root}/lib/crawler/my_aws"
require "#{Rails.root}/lib/crawler/my_util"
require 'date'
require 'open-uri'
require 'nokogiri'
require 'json'
@debug = false #true

  def batch
    # 日付からURLを得る
    url = FreeComics::Application.config.url_base_linemanga \
        + FreeComics::Application.config.url_list_linemanga \
        + (Date.today.wday + 1).to_s
    p "url=" + url
    # シリーズ一覧を得る
    doc = MyUtil.parse_html_with_proxy(url)
    # 各シリーズごとに処理
    doc.css('div .mdCMN04Item').each do |node|
      p '--------'
      #p node
      # シリーズのIDを取得
      series_sid_str = node.css('a').attribute("href").value if node.css('a').attribute("href")
      series_sid = series_sid_str.split("/product/periodic?id=").last if series_sid_str
      p "series_sid=" + series_sid

      # シリーズの概要と各話を取得
      detail_all_url = FreeComics::Application.config.url_base_linemanga \
                     + FreeComics::Application.config.url_detail_all_linemanga \
                     + series_sid
      #p "detail_all_url=" + detail_all_url
      doc_detail_all = MyUtil.parse_html_with_proxy(detail_all_url)
      hash = JSON.parse(doc_detail_all)
      #File.open("json.txt", "w") {|f| f.puts(JSON.pretty_generate(hash)) }
      title = hash['result']['product']['name']
      author =hash['result']['product']['author_name']
      thumbnail_org_url = hash['result']['product']['thumbnail']
      summary = hash['result']['product']['explanation']
      p "title=" + title + ", author=" + author
      #p thumbnail_org_url

      # 初めてのシリーズなら、サムネイル画像をCDNに保存して、DBに保存
      series = Series.find_by(title: title)
      if !series then
        # サムネイル画像の保存
        @s3_url = MyAws.upload_s3(thumbnail_org_url, FreeComics::Application.config.cdn_folder_linemanga)

        # サムネイル画像のURL付きでDBに保存
        @s = Series.create(sid: series_sid, title: title, author: author,
                          summary:summary, thumbnail_url: @s3_url)
        p "series inserted. id=" + @s.id.to_s
      end

      # シリーズ内の各話を処理
      @s ||= Series.find_by(title: title)
      #p "Series id=" + @s.id.to_s
      hash['result']['rows'].each do |row|
        p '---'
        topic_title = row['name']
        topic_payment = row['allow_charge']
        p "topic_title=" + topic_title
        p "topic_payment=" + topic_payment.to_s
        if !topic_payment then
          if !Topic.find_by(title: topic_title) then
            # 新しいtopicなら、サムネイル画像の保存とDBへの書き込み
            topic_thumbnail_org_url = row['thumbnail']
            topic_thumbnail_url = MyAws.upload_s3(topic_thumbnail_org_url, FreeComics::Application.config.cdn_folder_linemanga)
            p "topic_thumbnail_org_url=" + topic_thumbnail_org_url

            viewer_url = FreeComics::Application.config.url_base_linemanga \
                       + FreeComics::Application.config.url_viewer_linemanga \
                       + row['id']
            p "viewer_url=" + viewer_url
            store = Store.find_by(name: FreeComics::Application.config.store_name_linemanga)
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

            # 親の最終更新日時(topic_updated_at)も変更。(update_atは変更しない)
            @s.set(topic_updated_at: Time.now)
            @s.save
          end
        end
      end
      #デバッグ時は1シリーズ取得したら終了
      exit if @debug == true
    end
  end

  # 既存のシリーズ/トピックが無くなっていないかチェック
  def heartbeat
    # 各シリーズを取得
    # シリーズ内のトピックの、ビューアURLを開いて生存を確認
    # ビューアが開けなければ、そのトピックを削除
    # シリーズ内に(他ストアも含めて)一つもトピックが無ければ、シリーズも削除
  end
end
