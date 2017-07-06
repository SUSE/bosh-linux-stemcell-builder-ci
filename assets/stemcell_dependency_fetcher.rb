require 'json'
require 'uri'

module Bosh::Dev
  class StemcellDependencyFetcher
    def initialize(downloader, logger)
      @downloader = downloader
      @logger = logger
    end

    def download_os_image(opts)
      bucket_name = opts[:bucket_name]
      key = opts[:key]
      output_path = opts[:output_path]

      # https://forums.aws.amazon.com/thread.jspa?threadID=17989
      os_image_uri = URI.join("https://#{bucket_name}.s3.amazonaws.com/", key)

      # Always download the latest image version from S3.
      # Upstream always downloads the same version:
      # https://github.com/cloudfoundry/bosh-linux-stemcell-builder/blob/master/bosh-dev/lib/bosh/dev/stemcell_dependency_fetcher.rb#L16
      @downloader.download(os_image_uri, output_path)
    end
  end
end
