Pod::Spec.new do |s|

  s.name         = "autoScrollBanner"
  s.version      = “1.0.0”
  s.summary      = "autoScrollBanner"

  s.description  = <<-DESC
                   autoScrollBanner
                   DESC

  s.homepage     = "https://github.com/iunion/autoScrollBanner"
  s.license      = 'MIT'
  s.author       = { "Dennis Deng" => "iunion@live.cn" }


  s.platform     = :ios, '5.0'
  s.source       = { :git => "https://github.com/iunion/autoScrollBanner.git", :tag => s.version.to_s }

  s.source_files  = 'HMBannerView', 'HMBannerView/*.{h,m}'
  s.resources = "HMBannerView/Images/*.png"

end
