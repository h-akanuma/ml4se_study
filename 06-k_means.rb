# k平均法による画像の減色処理

require 'rmagick'
require 'numo/narray'

Colors = [2, 3, 5, 16]  # 減色後の色数

# k平均法による減色処理
def run_kmeans(pixels, k)
  cls = Array.new(pixels.size).fill(0)

  # 代表色の初期値をランダムに設定
  random = Random.new
  center = k.times.map { Numo::NArray[random.rand(256), random.rand(256), random.rand(256)] }
  puts "Initial centers: #{center.map(&:to_a)}"
  puts "========================"
  distortion = 0.0

  # 最大50回のIterationを実施
  50.times do |iter_num|
    center_new = Array.new(k).fill(Numo::NArray[0, 0, 0])
    num_points = Array.new(k).fill(0)
    distortion_new = 0.0

    # E Phase: 各データが属するグループ（代表色）を計算
    pixels.each_with_index do |point, pix|
      min_dist = 256 * 256 * 3
      point = Numo::NArray[*point]
      k.times do |i|
        d = (point - center[i]).cast_to(Numo::Int64).to_a.inject(0) {|sum, x| sum + (x ** 2) }
        if d < min_dist
          min_dist = d
          cls[pix] = i
        end

        center_new[cls[pix]] += point
        num_points[cls[pix]] += 1
        distortion_new += min_dist
      end
    end

    # M Phase: 新しい代表色を計算
    k.times do |i|
      if num_points[i] == 0
        center_new[i] = Numo::NArray[0, 0, 0]
        next
      end

      center_new[i] = center_new[i] / num_points[i]
    end
    center = center_new
    puts center.map(&:to_a).inspect
    puts "Distortion: J=#{distortion_new}"

    # Distortion(J)の変化が0.1%未満になったら終了
    if iter_num > 0 && distortion - distortion_new < distortion * 0.001
      break
    end
    distortion = distortion_new
  end

  # 画像データの各ピクセルを代表色で置き換え
  pixels.each_with_index do |point, pix|
    pixels[pix] = center[cls[pix]].to_a
  end

  pixels
end

Colors.each do |k|
  puts ""
  puts "========================"
  puts "Number of clusters: K=#{k}"

  # 画像ファイルの読み込み
  img = Magick::ImageList.new('./photo.jpg')
  pixels = img.export_pixels.map {|p| p / 257 }.each_slice(3).to_a

  # k平均法による減色処理
  result = run_kmeans(pixels, k)
  img.import_pixels(0, 0, img.columns, img.rows, "RGB", result.flatten.map {|p| p * 257 })
  img.write("bmp:output%02d.bmp" % k)
end
