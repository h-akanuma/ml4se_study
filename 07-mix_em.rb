# 混合ベルヌーイ分布による手書き文字分類

require 'csv'
require 'numo/narray'
require 'rmagick'

K = 3  # 分類する文字数
N = 10 # 反復回数

# 分類結果の表示
def show_figure(df, mu, cls)
  K.times do |c|
    rate = 1.0 / mu[c, 0..-1].max
    image = Magick::Image.new(28, 28)
    image.import_pixels(0, 0, 28, 28, 'I', mu[c, 0..-1].map {|v| 1 - v * rate }.to_a, Magick::FloatPixel)
    puts "Master #{c}"
    IRuby.display image

    cnt = 0
    cls.each_with_index do |v, i|
      if v == c
        rate = 1.0 / df[i].max
        image = Magick::Image.new(28, 28)
        image.import_pixels(0, 0, 28, 28, 'I', df[i].map {|d| 1 - d * rate }, Magick::FloatPixel)
        IRuby.display image
        cnt += 1
      end
      
      break if cnt == 6
    end
  end
end

# ベルヌーイ分布
def bern(x, mu)
  r = 1.0
  x.zip(mu).each do |x_i, mu_i|
    if x_i == 1
      r *= mu_i
      next
    end

    r *= (1.0 - mu_i)
  end

  r
end

# トレーニングセットの読み込み
df = CSV.read('sample-images.txt').map {|line| line.map(&:to_i) }
data_num = df.size

# 初期パラメータの設定
mix = [1.0 / K] * K
random = Random.new
mu = (Numo::NArray[*(28 * 28 * K).times.map { rand }] * 0.5 + 0.25).reshape(K, 28 * 28)

K.times do |k|
  mu[k, 0..-1] /= mu[k, 0..-1].sum
end

puts "initial"
K.times do |k|
  rate = 1.0 / mu[k, 0..-1].max
  image = Magick::Image.new(28, 28)
  image.import_pixels(0, 0, 28, 28, 'I', mu[k, 0..-1].map {|v| 1 - v * rate }.to_a, Magick::FloatPixel)
  IRuby.display image
end

resp = nil
N.times do |iter_num|
  puts "iter_num #{iter_num}"

  # E Phase
  resp = []
  df.each_with_index do |line, index|
    tmp = []
    K.times do |k|
      a = mix[k] * bern(line, mu[k, 0..-1])
      if a == 0.0
        tmp << 0.0
      else
        s = 0.0
        K.times do |kk|
          s += mix[kk] * bern(line, mu[kk, 0..-1])
        end
        tmp << a / s
      end
    end
    resp << tmp
  end

  # M Phase
  mu = Numo::DFloat.zeros(K, 28 * 28)
  K.times do |k|
    nk = resp.transpose[k].inject(:+)
    mix[k] = nk / data_num
    df.each_with_index do |line, index|
      mu[k, 0..-1] = mu[k, 0..-1] + Numo::NArray[*line].cast_to(Numo::DFloat) * resp[index][k]
    end
    mu[k, 0..-1] /= nk

    rate = 1.0 / mu[k, 0..-1].max
    image = Magick::Image.new(28, 28)
    image.import_pixels(0, 0, 28, 28, 'I', mu[k, 0..-1].map {|v| 1 - v * rate }.to_a, Magick::FloatPixel)
    IRuby.display image
  end
end

# トレーニングセットの文字を分類
cls = resp.map.with_index do |line, index|
  Numo::NArray[*line].max_index
end

# 分類結果の表示
show_figure(df, mu, cls)
