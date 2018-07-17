require 'aws-sdk'
class MyAws
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
    o.upload_file(upd_fullpath)
    return s3_path + '/' + file_name
  end
end
