namespace :crawler do
  desc "クローラ(サイトA)"
  task line_manga: :environment do
    Crawler::LineManga.batch
  end
  desc "クローラ(サイトB)"
  task line_manga2: :environment do
    Crawler::LineManga.batch
  end
end
