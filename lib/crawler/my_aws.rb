require 'aws-sdk'
require 'open-uri'
class MyAws
  @tempfilename = "image.tmp"

  def initialize
    @bucket_name = ENV['S3_BUCKET_NAME']

    Aws.config.update({
        region: 'ap-northeast-1',   # Tokyo region
        credentials: Aws::Credentials.new(ENV['S3_ACCESS_KEY'], ENV['S3_SECRET_KEY'])
    })

    s3 = Aws::S3::Resource.new
    @bucket = s3.bucket(@bucket_name)
    p 'bucket_name=' + @bucket_name
  end

  def send(s3_path, upd_fullpath, file_name)
    p 's3_path=' + s3_path
    p 'upd_fullpath=' + upd_fullpath
    p 'file_name=' + file_name
    o = @bucket.object(s3_path + '/' + file_name)
    #o.upload_file(upd_fullpath)
    o.upload_file(upd_fullpath, {acl:'public-read'})
    p 'public_url=' + o.public_url
    return o.public_url
  end

  def self.upload_s3(original_url)
    # サムネイル画像の保存
    open(original_url) { |image|
      #Tempfileだと2個目以降のファイルが書き込めないため、普通のファイルを使う
      File.binwrite(@tempfilename, image.read)
      # S3へアップロード(ファイル名の後ろのクエリ文字列は削除)
      ext = File.extname(original_url).slice(0, File.extname(original_url).index('?'))  # 拡張子のみ取り出す(「?time=1532328」等を削除)
      upload_filename = SecureRandom.urlsafe_base64 + ext
      p "upload_filename=" + upload_filename
      @aws ||= MyAws.new  # 初回のみ初期設定
      @s3_url = @aws.send(FreeComics::Application.config.cdn_folder_linemanga,
                          @tempfilename,
                          upload_filename)
    }
    File.unlink @tempfilename
    return @s3_url
  end
end
