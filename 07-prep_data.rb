# 手書き文字サンプルの抽出

CHARS = /[036]/ # 抽出する数字（任意の個数の数字を指定可能）
num = 600       # 抽出する文字数

labels = File.open('train-labels.txt', 'r')
images = File.open('train-images.txt', 'r')
labels_out = File.open('sample-labels.txt', 'w')
images_out = File.open('sample-images.txt', 'w')

while num > 0 do
  begin
    label = labels.readline
    image = images.readline
  rescue EOFError
    break
  end

  if label !~ CHARS
    next
  end

  line = image.split(' ').inject('') do |line, c|
    line += c.to_i > 127 ? '1,' : '0,'
  end

  line = line[0..-2]
  labels_out.puts(label)
  images_out.puts(line)
  num -= 1
end

labels.close
images.close
labels_out.close
images_out.close

images = File.open('sample-images.txt', 'r')
samples = File.open('samples.txt', 'w')

c = 0
while c < 10 do
  begin
    line = images.readline
  rescue EOFError
    break
  end

  x = 0
  line.split(',').each do |s|
    samples.write(s.to_i == 1 ? '#' : ' ')
    x += 1

    if x % 28 == 0
      samples.puts('')
    end
  end

  c += 1
end

images.close
samples.close
